module Api
  module V1
    class Appuser < Grape::API
      include Api::V1::Defaults

      helpers do
        def fetch_user
          user = valid_user(params[:userId], params[:securityToken])
          return { status: 500, message: INVALID_SESSION } unless user
          return { status: 500, message: "You are banned. Please contact support." } if user.is_banned
          user
        end
      end

      resource :allCategories do
        before { api_params }
        params { use :common_params }

        post do
          user = fetch_user
          categories = Category.published.limit(20).to_a
          { status: 200, message: MSG_SUCCESS, categories: categories, walletBalance: user.wallet_balance }
        rescue StandardError => e
          Rails.logger.info "API Exception-#{Time.now}-allCategories-#{params.inspect}-Error-#{e}"
          { status: 500, message: "Server under maintenance" }
        end
      end

      %i[upcoming live completed].each do |state|
        resource "#{state}Matches" do
          before { api_params }
          params do
            use :common_params
            requires :categoryId, type: String
          end

          post do
            user = fetch_user
            matches = Match.where(category_id: params[:categoryId]).send(state).limit(20).to_a
            { status: 200, message: MSG_SUCCESS, matches: matches, walletBalance: user.wallet_balance }
          rescue StandardError => e
            Rails.logger.info "API Exception-#{Time.now}-#{state}Matches-#{params.inspect}-Error-#{e}"
            { status: 500, message: "Server under maintenance" }
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
          user = fetch_user
          players = Player.where(match_id: params[:matchId]).to_a
          { status: 200, message: MSG_SUCCESS, players: players, walletBalance: user.wallet_balance }
        rescue StandardError => e
          Rails.logger.info "API Exception-#{Time.now}-players-#{params.inspect}-Error-#{e}"
          { status: 500, message: "Server under maintenance" }
        end
      end

      resource :joinTeam do
        before { api_params }
        params do
          use :common_params
          requires :matchId, :name, :uid, :username, type: String
        end

        post do
          user = fetch_user
          match = Match.find_by(id: params[:matchId])
          return { status: 500, message: "Match not found" } if match.nil?
          return { status: 500, message: "Already Joined the Team" } if Player.exists?(match_id: match.id, user_id: user.id)
          return { status: 500, message: "Insufficient Funds!" } if user.wallet_balance < match.entry_fee

          ActiveRecord::Base.transaction do
            match.lock!
            available_slots = (1..match.total_slots).to_a - match.players.pluck(:slot_no)
            return { status: 500, message: "No slots available!" } if available_slots.empty?

            user.update!(wallet_balance: user.wallet_balance - match.entry_fee)
            match.update!(slots_left: match.slots_left - 1)

            player = match.players.create!(user_id: user.id, name: params[:name], uid: params[:uid], username: params[:username], slot_no: available_slots.sample)
            user.user_matches.create!(match_id: match.id, player_id: player.id)
          end

          { status: 200, message: "Joined Team Successfully", walletBalance: user.wallet_balance }
        rescue StandardError => e
          Rails.logger.info "API Exception-#{Time.now}-joinTeam-#{params.inspect}-Error-#{e}"
          { status: 500, message: "Server under maintenance" }
        end
      end

      resource :redeem do
        before { api_params }
        params do
          use :common_params
          requires :upiId, :mobileNumber, type: String
          requires :amount, type: Integer
        end

        post do
          user = fetch_user
          return { status: 500, message: "Insufficient Funds!" } if user.wallet_balance < params[:amount]

          return { status: 500, message: "Minimum Withrawl limit is ₹100" } if params[:amount] < 100

          user.redeems.create!(amount: params[:amount], upi_id: params[:upiId], mobile_number: params[:mobileNumber])
          { status: 200, message: "Redeem Request Submitted Successfully" }
        rescue StandardError => e
          Rails.logger.info "API Exception-#{Time.now}-redeem-#{params.inspect}-Error-#{e}"
          { status: 500, message: "Server under maintenance" }
        end
      end

      resource :appBanners do
        before { api_params }
        params do
          use :common_params
        end

        post do
          user = fetch_user
          banners = AppBanner.active.to_a
          { status: 200, message: MSG_SUCCESS, appBanners: banners }
        rescue StandardError => e
          Rails.logger.info "API Exception-#{Time.now}-appBanners-#{params.inspect}-Error-#{e}"
          { status: 500, message: "Server under maintenance" }
        end
      end

      resource :userMatches do
        before { api_params }
        params do
          use :common_params
        end

        post do
          user = fetch_user
          matches = UserMatch.includes(:match, :player).order(created_at: :desc).limit(20).map do |um|
            { match: um.match, player: um.player }
          end
          { status: 200, message: MSG_SUCCESS, matches: matches }
        rescue StandardError => e
          Rails.logger.info "API Exception-#{Time.now}-userMatches-#{params.inspect}-Error-#{e}"
          { status: 500, message: "Server under maintenance" }
        end
      end

      resource :capturePayment do
        before { api_params }
        params do
          use :common_params
          requires :razorpayPaymentId, type: String
        end

        post do
          user = fetch_user
          # user.update(wallet_balance: user.wallet_balance + params[])
          require "net/http"
          require "uri"
          require "json"

          key_id = "rzp_live_PAE3MFBLHAckwG"
          key_secret = "k2RtLSJR28erCjeKN0HFupfE"

          url = URI("https://api.razorpay.com/v1/payments/#{params[:razorpayPaymentId]}/capture")

          body = {
            amount: AppConfig.first.min_deposit.to_i * 100,
          }.to_json

          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new(url)
          request.basic_auth(key_id, key_secret)
          request["Content-Type"] = "application/json"
          request.body = body
          response = http.request(request)

          if response.body["captured"]
            url = URI("https://api.razorpay.com/v1/payments/#{params[:razorpayPaymentId]}")
            body = {
              amount: AppConfig.first.min_deposit.to_i * 100,
            }.to_json
            http = Net::HTTP.new(url.host, url.port)
            http.use_ssl = true
            request = Net::HTTP::Post.new(url)
            request.basic_auth(key_id, key_secret)
            request["Content-Type"] = "application/json"
            request.body = body
            response = http.request(request)
            user.update(wallet_balance: user.wallet_balance + AppConfig.first.min_deposit.to_i)
            { status: 200, message: "Payment Success", walletBalance: user.wallet_balance }
          end
        rescue StandardError => e
          Rails.logger.info "API Exception-#{Time.now}-capturePayment-#{params.inspect}-Error-#{e}"
          { status: 500, message: "Server under maintenance" }
        end
      end
    end
  end
end
