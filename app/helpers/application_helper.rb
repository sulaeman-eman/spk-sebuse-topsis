module ApplicationHelper
  ROLE_LABELS = {
    "super_admin" => "Super Admin",
    "admin_panitia" => "Admin Panitia",
    "peserta" => "Peserta"
  }.freeze

  ACTIVITY_TYPE_LABELS = {
    "cardio" => "Cardio",
    "strength" => "Strength",
    "long_run" => "Long Run",
    "fun_sport" => "Fun Sports"
  }.freeze

  def role_label(user)
    ROLE_LABELS.fetch(user.role, user.role.to_s.humanize)
  end

  def activity_type_label(activity_type)
    ACTIVITY_TYPE_LABELS.fetch(activity_type.to_s, activity_type.to_s.humanize)
  end

  # Penanda menu aktif dibandingkan berdasarkan controller tujuan, bukan awalan
  # URL. Tanpa itu menu "Event" ikut menyala saat membuka /events/1/leaderboard,
  # karena jalurnya memang berawalan sama.
  def nav_link(label, path)
    link_to label, path, class: "nav__link#{' nav__link--active' if nav_active?(path)}"
  end

  def nav_active?(path)
    target = Rails.application.routes.recognize_path(path)

    target[:controller] == controller_path
  rescue ActionController::RoutingError
    current_page?(path)
  end

  # Angka desimal ditampilkan 4 digit, presisi yang dipakai sepanjang Bab IV.
  def decimal4(value)
    return "-" if value.blank?

    number_with_precision(value, precision: 4)
  end

  def decimal2(value)
    return "-" if value.blank?

    number_with_precision(value, precision: 2)
  end

  def percent(weight)
    return "-" if weight.blank?

    "#{number_with_precision(weight.to_f * 100, precision: 2, strip_insignificant_zeros: true)}%"
  end

  # Tingkat capaian skor untuk pewarnaan batang pada rincian skor.
  def score_tier(value)
    case value.to_f
    when 80.. then "high"
    when 50...80 then "mid"
    else "low"
    end
  end
end
