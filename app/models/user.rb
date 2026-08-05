class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :participants, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Tiga aktor pada use case diagram Bab IV.C.1.
  enum :role, { super_admin: 0, admin_panitia: 1, peserta: 2 }

  validates :name, presence: true
  # Tanpa validasi ini, email kembar menabrak indeks unik database dan berujung
  # galat 500 alih-alih pesan kesalahan pada formulir.
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }

  # Hak akses per use case.
  def manages_users?    = super_admin?
  def manages_criteria? = super_admin?
  def runs_topsis?      = super_admin? || admin_panitia?
end
