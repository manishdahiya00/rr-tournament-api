module API
  class Base < Grape::API
    mount API::V1::Auth
    mount API::V1::Appuser
  end
end
