Rails.application.routes.draw do
  # UC-01 Login
  resource :session
  resources :passwords, param: :token

  root "dashboards#show"

  # UC-02 Kelola Data Pengguna (Super Admin)
  resources :users

  # UC-03 Kelola Kriteria dan Bobot (Super Admin)
  resources :criteria, only: %i[index] do
    patch :update_weights, on: :collection
  end

  resources :events, only: %i[index show edit update] do
    # UC-04 Kelola Data Peserta
    resources :participants, only: %i[index new create edit update destroy]

    # UC-06 Pre-processing Data
    resource :preprocessing, only: %i[show create]

    # UC-07 Hitung Metode TOPSIS
    resources :topsis_runs, only: %i[index show create]

    # UC-08 Lihat Papan Peringkat
    resource :leaderboard, only: %i[show]

    # UC-05 Import Log Activities
    resources :activity_log_imports, only: %i[new create destroy], path: "impor-log" do
      get :template, on: :collection
    end

    # UC-10 Cetak Laporan Peringkat
    resources :reports, only: %i[show], path: "laporan"
  end

  # Input log aktivitas peserta secara manual per baris
  resources :participants, only: [] do
    resources :activity_logs, only: %i[index new create destroy]
  end

  # UC-09 Lihat Detail Skor Individu
  resources :scores, only: %i[show]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
