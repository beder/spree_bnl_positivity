Spree::Core::Engine.routes.draw do
  match '/bnl',         to: "bnl_positivity_redirect#buy_now",        as: :bnl_positivity,          via: [:get, :post]
  match "/bnl/notify",  to: "bnl_positivity_notifications#notify",    as: :bnl_positivity_notify,   via: [:get, :post]
  match "/bnl/error",   to: "bnl_positivity_notifications#error",     as: :bnl_positivity_error,    via: [:get, :post]
end