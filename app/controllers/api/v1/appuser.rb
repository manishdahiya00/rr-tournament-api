module Api
  module V1
    class Appuser < Grape::API
      include API::V1::Defaults

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
            Category.published.limit(20).each do |category|
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
            match = Match.find(params[:matchId])
            if !match
              return { status: 500, message: "Match not found" }
            end
            existingPlayer = Player.find_by(match_id: match.id, user_id: user.id)
            if existingPlayer
              return { status: 500, message: "Already Joined the Team" }
            end
            if user.wallet_balance < match.entry_fee
              return { status: 500, message: "Insufficient Funds!" }
            end
            newBalance = user.wallet_balance - match.entry_fee
            user.update(wallet_balance: newBalance)
            match.update(slots_left: match.slots_left - 1)
            match.players.create(user_id: user.id, name: params[:name], uid: params[:uid], username: params[:username])
            { status: 200, message: "Joined Team Successfully", walletBalance: newBalance }
          rescue Exception => e
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
    end
  end
end
