module VideosHelper
  def format_view_count(count)
    count = count.to_i

    if count >= 100_000_000
      "#{count / 100_000_000}億回"
    elsif count >= 10_000
      "#{count / 10_000}万回"
    else
      "#{number_with_delimiter(count)}回"
    end
  end

  def current_search(overrides = {})
    base_params = params[:search]

    base =
      if base_params.is_a?(ActionController::Parameters)
        base_params.permit(:q, :limit, :sort, :direction, :published_before, :published_after).to_h
      else
        (base_params || {}).slice(:q, :limit, :sort, :direction, :published_before, :published_after)
      end

    base.merge(overrides).compact
  end

  def toggle_direction(direction)
    direction == "asc" ? "desc" : "asc"
  end

  def next_direction_for(target)
    current_sort = (params.dig(:search, :sort) || "viewCount")
    current_dir  = (params.dig(:search, :direction) || "desc")
    current_sort == target ? toggle_direction(current_dir) : "desc"
  end
end
