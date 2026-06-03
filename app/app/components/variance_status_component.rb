class VarianceStatusComponent < ViewComponent::Base
  def initialize(tag:)
    @tag = tag
  end

  def render?
    @tag.both_sided?
  end

  def call
    threshold = "±#{(@tag.tolerance_fraction * 100).round(2)}%"
    if @tag.within_tolerance?
      callout("text-status-matched", "Within tolerance (#{threshold})", check_icon)
    else
      callout("text-status-review", "Exceeds tolerance (#{threshold})", alert_icon)
    end
  end

  private

  def callout(color, text, icon)
    content_tag :div, class: "border-t border-border bg-secondary/40 px-6 py-3" do
      content_tag :div, class: "flex items-center justify-between" do
        safe_join([
          content_tag(:div, "Variance Status:", class: "text-sm font-medium"),
          content_tag(:div, class: "inline-flex items-center gap-2 text-sm font-medium #{color}") do
            safe_join([ icon, content_tag(:span, text) ])
          end
        ])
      end
    end
  end

  def check_icon
    tag.svg(class: "h-4 w-4", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": "2") do
      tag.path(d: "M20 6 9 17l-5-5")
    end
  end

  def alert_icon
    tag.svg(class: "h-4 w-4", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": "2") do
      safe_join([ tag.circle(cx: "12", cy: "12", r: "10"), tag.path(d: "M12 8v4M12 16h.01") ])
    end
  end
end
