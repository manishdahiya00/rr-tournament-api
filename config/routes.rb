Rails.application.routes.draw do
  devise_for :admins

  authenticate :admin do
    mount Motor::Admin => "/rr/official"
  end
  get "up" => "rails/health#show", as: :rails_health_check

  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  mount Api::Base => "/"
end
