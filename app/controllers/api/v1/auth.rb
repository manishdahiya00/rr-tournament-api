module Api
  module V1
    class Auth < Grape::API
      include Api::V1::Defaults

      resource :userSignup do
        before { api_params }

        params do
          requires :name, type: String, allow_blank: false
          requires :email, type: String, allow_blank: false
          requires :password, type: String, allow_blank: false
        end
        post do
          begin
            user = User.find_by(email: params[:email])
            unless user.present?
              source_ip = request.ip
              user = User.create(name: params[:name], email: params[:email], password: params[:password], security_token: SecureRandom.uuid, source_ip: source_ip, wallet_balance: AppConfig.first.signup_bonus)
              { status: 200, message: "Registered Successfully", userId: user.id, securityToken: user.security_token, walletBalance: user.wallet_balance, name: user.name, email: user.email }
            else
              { status: 500, message: "User already registered." }
            end
          rescue Exception => e
            Rails.logger.info "API Exception-#{Time.now}-userSignUp-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end

      resource :userSignin do
        before { api_params }

        params do
          requires :email, type: String, allow_blank: false
          requires :password, type: String, allow_blank: false
        end
        post do
          begin
            user = User.find_by(email: params[:email])
            unless user.present?
              { status: 500, message: "Invalid email or password" }
            end
            unless user&.authenticate(params[:password])
              return { status: 500, message: "Invalid email or password" }
            end
            if user.is_banned
              return { status: 500, message: "You are banned from using application." }
            end
            { status: 200, message: "Signed In Successfully", userId: user.id, securityToken: user.security_token, walletBalance: user.wallet_balance, name: user.name, email: user.email }
          rescue Exception => e
            Rails.logger.info "API Exception-#{Time.now}-userSignUp-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end

      resource :appOpen do
        before { api_params }

        params do
          use :common_params
        end
        post do
          begin
            user = valid_user(params[:userId], params[:securityToken])
            return { status: 500, message: "Invalid Session" } unless user.present?
            source_ip = request.ip
            { status: 500, message: "Server On Maintainance" }
            # { status: 200, message: MSG_SUCCESS, walletBalance: user.wallet_balance, name: user.name, email: user.email, phn1: AppConfig.first.phn1, phn2: AppConfig.first.phn2, tel1: AppConfig.first.tel1, tel2: AppConfig.first.tel2, bannerImage: AppConfig.first.banner_image }
          rescue Exception => e
            Rails.logger.info "API Exception-#{Time.now}-appOpen-#{params.inspect}-Error-#{e}"
            { status: 500, message: MSG_ERROR }
          end
        end
      end
    end
  end
end
