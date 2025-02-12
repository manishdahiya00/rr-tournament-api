module Api
  module V1
    class Auth < Grape::API
      include Api::V1::Defaults

      helpers do
        def send_otp(phone, otp)
          account_sid = "AC1313e2357a15abf117fedb028658ebd7"
          auth_token = "82beaffc0faf9924984a35f3085ab1c6"

          begin
            client = Twilio::REST::Client.new(account_sid, auth_token)

            lookup = client.lookups.v2.phone_numbers("+91#{phone}").fetch()
            return { status: 500, message: "Invalid phone number. Please enter a valid number." } unless lookup&.valid

            client.messages.create(
              body: "Your OTP for RR Official is #{otp}",
              to: "+91#{phone}",
              from: "+15076937451",
            )

            { status: 200, message: "OTP Sent Successfully" }
          rescue Twilio::REST::RestError => e
            Rails.logger.info "Twilio Error: #{e.message}"
            { status: 500, message: "Invalid phone number. Please enter a valid number." }
          rescue StandardError => e
            Rails.logger.info "Send OTP Exception: #{e.message}"
            { status: 500, message: "Something went wrong: #{e.message}" }
          end
        end
      end
      resource :auth do
        before { api_params }

        params do
          requires :phone, type: String, allow_blank: false
          optional :referralCode, type: String, allow_blank: true
          requires :versionName, type: String, allow_blank: false
          requires :versionCode, type: String, allow_blank: false
        end

        post do
          phone = params[:phone]
          otp = SecureRandom.random_number(10 ** 6).to_s.rjust(6, "0")

          user = User.find_or_initialize_by(phone: phone)

          user.refer_code ||= SecureRandom.hex(4)

          if params[:referralCode].present?
            referral_user = User.find_by(refer_code: params[:referralCode])
            return { status: 500, message: "Invalid Referral Code" } unless referral_user

            return { status: 500, message: "Can't use your own referral code" } if user.refer_code == params[:referralCode]
          end

          otp_response = send_otp(phone, otp)
          return otp_response if otp_response[:status] != 200

          begin
            user.otp = otp
            user.security_token ||= SecureRandom.uuid
            user.wallet_balance ||= AppConfig.first.signup_bonus
            user.source_ip ||= request.ip
            user.version_name ||= params[:versionName]
            user.version_code ||= params[:versionCode]

            if params[:referralCode].present?
              user.referral_code = params[:referralCode]
              referral_user.update(wallet_balance: referral_user.wallet_balance + AppConfig.first.refer_bonus)
            end

            user.save!

            otp_response.merge(userId: user.id, securityToken: user.security_token, referCode: user.refer_code)
          rescue StandardError => e
            Rails.logger.info "API Exception-#{Time.now}-auth-#{params.inspect}-Error-#{e}"
            { status: 500, message: "Something went wrong, please try again." }
          end
        end
      end

      resource :verifyOtp do
        before { api_params }

        params do
          requires :otp, type: String, allow_blank: false
          requires :phone, type: String, allow_blank: false
        end

        post do
          user = User.find_by(phone: params[:phone])
          return { status: 500, message: "User not found" } unless user

          if user.otp == params[:otp]
            user.update(otp: "")
            {
              status: 200,
              message: "Signed In Successfully",
              userId: user.id,
              securityToken: user.security_token,
              walletBalance: user.wallet_balance,
              phone: user.phone,
              phn1: AppConfig.first.phn1,
              phn2: AppConfig.first.phn2,
              tel1: AppConfig.first.tel1,
              tel2: AppConfig.first.tel2,
              bannerImage: AppConfig.first.banner_image,
              referCode: user.refer_code,
            }
          else
            { status: 500, message: "Invalid OTP" }
          end
        rescue StandardError => e
          Rails.logger.info "API Exception-#{Time.now}-verifyOtp-#{params.inspect}-Error-#{e}"
          { status: 500, message: "Something went wrong, please try again." }
        end
      end

      resource :appOpen do
        before { api_params }

        params do
          use :common_params
        end

        post do
          user = valid_user(params[:userId], params[:securityToken])
          return { status: 500, message: "Invalid Session" } unless user

          {
            status: 200,
            message: "Success",
            walletBalance: user.wallet_balance,
            phone: user.phone,
            phn1: AppConfig.first.phn1,
            phn2: AppConfig.first.phn2,
            tel1: AppConfig.first.tel1,
            tel2: AppConfig.first.tel2,
            bannerImage: AppConfig.first.banner_image,
            referCode: user.refer_code,
            version: AppConfig.first.version,
            updateUrl: AppConfig.first.update_url,
          }
        rescue StandardError => e
          Rails.logger.info "API Exception-#{Time.now}-appOpen-#{params.inspect}-Error-#{e}"
          { status: 500, message: "Something went wrong, please try again." }
        end
      end
    end
  end
end
