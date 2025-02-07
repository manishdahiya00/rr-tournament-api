module Api
  class Base < Grape::API
    mount Api::V1::Auth
    mount Api::V1::Appuser
  end
end
