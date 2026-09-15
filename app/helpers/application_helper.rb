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

  # Ikon garis 24x24 yang dipakai navigasi, notifikasi, dan penanda peringkat.
  # Ditulis inline agar tidak menambah permintaan berkas maupun tahap build, dan
  # agar warnanya ikut currentColor tiap komponen.
  ICONS = {
    pulse: "M3 12h3.5l2-6 3.5 12 2.5-8 1.8 4H21",
    gauge: "M12 14l3.5-3.5M4 19a9 9 0 1 1 16 0",
    calendar: "M7 3v3m10-3v3M4 8h16M5 5h14a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z",
    sliders: "M4 7h10m4 0h2M4 17h4m4 0h8M16 4v6M10 14v6",
    users: "M16 19v-1a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v1M9.5 10.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM17 4.5a3 3 0 0 1 0 6M21 19v-1a3.6 3.6 0 0 0-2.5-3.4",
    upload: "M12 16V4m0 0L8 8m4-4 4 4M4 15v3a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-3",
    funnel: "M4 5h16l-6 7v6l-4 2v-8L4 5z",
    calculator: "M6 3h12a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM9 7h6M9 11h.01M12 11h.01M15 11h.01M9 15h.01M12 15h.01M15 15h.01M9 18h6",
    trophy: "M8 4h8v5a4 4 0 0 1-8 0V4zM8 5H5v2a3 3 0 0 0 3 3M16 5h3v2a3 3 0 0 1-3 3M10 17h4M9 20h6M12 13v4",
    shield: "M12 3l7 3v6c0 4-3 7-7 8-4-1-7-4-7-8V6l7-3zM12 12.5a2 2 0 1 0 0-4 2 2 0 0 0 0 4zM8.5 16a3.6 3.6 0 0 1 7 0",
    logout: "M15 17l5-5-5-5M20 12H9M12 4H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h6",
    check: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM8.5 12.5l2.5 2.5 4.5-5",
    alert: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 8v5M12 16.5v.01",
    inbox: "M4 13h4l1.5 2.5h5L16 13h4M4 13l2.5-7h11L20 13v5a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-5z",
    medal: "M12 21a5 5 0 1 0 0-10 5 5 0 0 0 0 10zM12 18.5l-1.8 1 .4-2-1.5-1.4 2-.3.9-1.8.9 1.8 2 .3-1.5 1.4.4 2-1.8-1zM8.5 3h7l-2 6h-3l-2-6z",
    file: "M13 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V9l-6-6zM13 3v6h6M9 14h6M9 17h4"
  }.freeze

  def icon(name, size: 20)
    path = ICONS.fetch(name.to_sym) { raise ArgumentError, "ikon #{name} belum tersedia" }

    tag.svg(tag.path(d: path).html_safe,
            viewBox: "0 0 24 24", width: size, height: size, fill: "none",
            stroke: "currentColor", "stroke-width": 1.6,
            "stroke-linecap": "round", "stroke-linejoin": "round",
            "aria-hidden": true, focusable: false)
  end

  def role_label(user)
    ROLE_LABELS.fetch(user.role, user.role.to_s.humanize)
  end

  # Inisial untuk avatar akun pada bilah sisi; maksimal dua huruf.
  def user_initials(user)
    user.name.to_s.split.first(2).map { |word| word[0] }.join.upcase.presence || "?"
  end

  def activity_type_label(activity_type)
    ACTIVITY_TYPE_LABELS.fetch(activity_type.to_s, activity_type.to_s.humanize)
  end

  # Penanda menu aktif dibandingkan berdasarkan controller tujuan, bukan awalan
  # URL. Tanpa itu menu "Event" ikut menyala saat membuka /events/1/leaderboard,
  # karena jalurnya memang berawalan sama.
  def nav_link(label, path, icon_name = nil)
    link_to path, class: "nav__link#{' nav__link--active' if nav_active?(path)}" do
      safe_join([ (icon(icon_name, size: 17) if icon_name), tag.span(label) ].compact)
    end
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

  # Sebutan juara beserta medali untuk tiga peringkat teratas.
  def rank_badge(result)
    tag.span(class: "rank rank--#{result.rank}") do
      safe_join([ (icon(:medal, size: 15) if result.rank <= 3), result.award_label ].compact)
    end
  end
end
