module Api
  module V1
    class Appuser < Grape::API
      include Api::V1::Defaults

      resource :allCategories do
        before { api_params }

        params do
          use :common_params
        end
        post do
          begin
            user = valid_user(params[:userId], params[:securityToken])
            return { status: 500, message: INVALID_SESSION } unless user.present?
            categories = []
            # player = Player.find_by(user_id: user.id)
            # is_match_joined = false
            Category.published.limit(20).each do |category|
              # if player
              #   category.matches.where(status: "upcoming").each do |match|
              #     if match.id == player.match_id
              #       is_match_joined = true
              #     end
              #   end
              # end
              categories << category
            end
            { status: 200, message: MSG_SUCCESS, categories: categories || [], walletBalance: user.wallet_balance }
          rescue Exception => e
            Rails.logger.info "API Exception-#{Time.now}-allcategories-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end
      resource :upcomingMatches do
        before { api_params }

        params do
          use :common_params
          requires :categoryId, type: String
        end
        post do
          begin
            user = valid_user(params[:userId], params[:securityToken])
            return { status: 500, message: INVALID_SESSION } unless user.present?
            matches = []
            Match.where(category_id: params[:categoryId]).upcoming.limit(20).each do |match|
              matches << match
            end
            { status: 200, message: MSG_SUCCESS, matches: matches || [], walletBalance: user.wallet_balance }
          rescue Exception => e
            Rails.logger.info "API Exception-#{Time.now}-upcomingMatches-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end
      resource :liveMatches do
        before { api_params }

        params do
          use :common_params
          requires :categoryId, type: String
        end
        post do
          begin
            user = valid_user(params[:userId], params[:securityToken])
            return { status: 500, message: INVALID_SESSION } unless user.present?
            matches = []
            Match.where(category_id: params[:categoryId]).live.limit(20).each do |match|
              matches << match
            end
            { status: 200, message: MSG_SUCCESS, matches: matches || [], walletBalance: user.wallet_balance }
          rescue Exception => e
            Rails.logger.info "API Exception-#{Time.now}-liveMatches-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end
      resource :completedMatches do
        before { api_params }

        params do
          use :common_params
          requires :categoryId, type: String
        end
        post do
          begin
            user = valid_user(params[:userId], params[:securityToken])
            return { status: 500, message: INVALID_SESSION } unless user.present?
            matches = []
            Match.where(category_id: params[:categoryId]).completed.limit(20).each do |match|
              matches << match
            end
            { status: 200, message: MSG_SUCCESS, matches: matches || [], walletBalance: user.wallet_balance }
          rescue Exception => e
            Rails.logger.info "API Exception-#{Time.now}-completedMatches-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end
      resource :players do
        before { api_params }

        params do
          use :common_params
          requires :matchId, type: String
        end
        post do
          begin
            user = valid_user(params[:userId], params[:securityToken])
            return { status: 500, message: INVALID_SESSION } unless user.present?
            players = []
            Player.where(match_id: params[:matchId]).each do |player|
              players << player
            end
            { status: 200, message: MSG_SUCCESS, players: players || [], walletBalance: user.wallet_balance }
          rescue Exception => e
            Rails.logger.info "API Exception-#{Time.now}-players-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end
      resource :joinTeam do
        before { api_params }

        params do
          use :common_params
          requires :matchId, type: String
          requires :name, type: String
          requires :uid, type: String
          requires :username, type: String
        end

        post do
          begin
            user = valid_user(params[:userId], params[:securityToken])
            return { status: 500, message: INVALID_SESSION } unless user.present?

            match = Match.find_by(id: params[:matchId])
            return { status: 500, message: "Match not found" } unless match

            existing_player = Player.find_by(match_id: match.id, user_id: user.id)
            return { status: 500, message: "Already Joined the Team" } if existing_player

            return { status: 500, message: "Insufficient Funds!" } if user.wallet_balance < match.entry_fee

            ActiveRecord::Base.transaction do
              match.lock!

              assigned_slots = match.players.pluck(:slot_no).compact.uniq.map(&:to_i)

              total_slots = (1..match.total_slots).to_a
              available_slots = total_slots - assigned_slots

              return { status: 500, message: "No slots available!" } if available_slots.empty?

              slot_no = available_slots.sample
              user.update!(wallet_balance: user.wallet_balance - match.entry_fee)
              match.update!(slots_left: match.slots_left - 1)

              player = match.players.create!(
                user_id: user.id,
                name: "#{params[:name]}",
                uid: params[:uid],
                username: params[:username],
                slot_no: slot_no,
              )
              user.user_matches.create(match_id: match.id, player_id: player.id)
              { status: 200, message: "Joined Team Successfully", walletBalance: user.wallet_balance }
            end
          rescue ActiveRecord::RecordInvalid => e
            Rails.logger.info "Database Error-#{Time.now}-joinTeam-#{params.inspect}-Error-#{e}"
            { status: 500, message: "Database error. Please try again." }
          rescue StandardError => e
            Rails.logger.info "API Exception-#{Time.now}-joinTeam-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end
      resource :redeem do
        before { api_params }

        params do
          use :common_params
          requires :upiId, type: String
          requires :mobileNumber, type: String
          requires :amount, type: Integer
        end
        post do
          begin
            user = valid_user(params[:userId], params[:securityToken])
            return { status: 500, message: INVALID_SESSION } unless user.present?
            if user.wallet_balance < params[:amount]
              return { status: 500, message: "Insufficient Funds!" }
            end
            user.redeems.create(amount: params[:amount], upi_id: params[:upiId], mobile_number: params[:mobileNumber])
            { status: 200, message: "Redeem Request Submitted Successfully" }
          rescue Exception => e
            Rails.logger.info "API Exception-#{Time.now}-joinTeam-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end
      resource :appBanners do
        before { api_params }

        params do
          use :common_params
        end
        post do
          begin
            user = valid_user(params[:userId], params[:securityToken])
            return { status: 500, message: INVALID_SESSION } unless user.present?
            app_banners = []
            AppBanner.active.each do |app_banner|
              app_banners << app_banner
            end
            { status: 200, message: MSG_SUCCESS, appBanners: app_banners }
          rescue Exception => e
            Rails.logger.info "API Exception-#{Time.now}-appBanners-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end
      resource :userMatches do
        before { api_params }

        params do
          use :common_params
        end
        post do
          begin
            user = valid_user(params[:userId], params[:securityToken])
            return { status: 500, message: INVALID_SESSION } unless user.present?
            matches = []
            UserMatch.all().order(created_at: :desc).limit(20).each do |user_match|
              matches << {
                match: user_match.match,
                player: user_match.player,
              }
            end
            { status: 200, message: MSG_SUCCESS, matches: matches || [] }
          rescue Exception => e
            Rails.logger.info "API Exception-#{Time.now}-upcomingMatches-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end
    end
  end
end
