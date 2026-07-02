module ApplicationHelper
  def th_class(align = nil)
    [ "px-4 py-2 font-medium text-xs text-muted-foreground", (align && "text-#{align}") ].compact.join(" ")
  end

  def field_class(variant = :input)
    case variant
    when :filter then "px-3 py-1.5 text-sm rounded-md border border-border bg-card"
    else "px-3 py-2 rounded-md bg-input-background border border-border text-sm"
    end
  end

  def lb(value)
    value.nil? ? "—" : number_with_delimiter(value.to_i)
  end

  def fmt_date(value)
    value ? value.strftime("%b %-d, %Y") : "—"
  end

  def fmt_datetime(value)
    value ? value.strftime("%b %-d, %Y %l:%M %p") : "—"
  end

  def fmt_short_date(value)
    value ? value.strftime("%m/%d/%Y") : "—"
  end

  def signed_percent(number)
    return "—" if number.nil?
    "#{'+' if number.positive?}#{number}%"
  end

  def btn_class(variant = :secondary, size: :sm)
    pad = { sm: "px-3 py-1.5 text-sm", md: "px-3 py-2 text-sm", lg: "px-4 py-2.5" }.fetch(size)
    look = case variant
    when :primary then "bg-primary text-primary-foreground font-medium"
    else "border border-border bg-card hover:bg-secondary"
    end
    "#{pad} rounded-md cursor-pointer #{look}"
  end
end
