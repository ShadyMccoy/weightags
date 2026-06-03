class DeltaCellComponent < ViewComponent::Base
  def initialize(tag:, metric:, show_pct: false)
    @tag = tag
    @metric = metric
    @show_pct = show_pct
  end

  def render?
    @tag.both_sided?
  end

  def call
    delta = @tag.delta(@metric)
    return content_tag(:span, "—", class: "text-muted-foreground") if delta.nil?

    exceeds = @tag.exceeds_tolerance?
    color = exceeds ? "text-status-review" : "text-status-matched"

    pct = @tag.net_delta_percent
    safe_join([
      content_tag(:div, format_signed(delta), class: "font-mono tabular-nums #{color}"),
      (@show_pct && pct ? content_tag(:div, "(#{helpers.signed_percent(pct)})",
        class: "text-xs font-mono tabular-nums #{exceeds ? 'text-status-review' : 'text-muted-foreground'}") : nil)
    ].compact)
  end

  private

  def format_signed(value)
    "#{'+' if value.positive?}#{number_with_delimiter(value.to_i)}"
  end
end
