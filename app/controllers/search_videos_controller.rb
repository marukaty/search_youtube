class SearchVideosController < ApplicationController
  def index; end

  def video_lists
    video_items = Kaminari.paginate_array(Youtube::SearchVideos.call(search_params))
    video_items.reverse! if search_params[:direction] == "asc"
    @videos = video_items.page(params[:page]).per(9)
    render :video_lists, formats: :turbo_stream
  end

  private

  def search_params
    params.require(:search).permit(:q, :limit, :sort, :direction, :page_token, :published_after, :published_before)
  end

  def user_friendly_message(error)
    case error.message
    when /quota/i
      "APIクォータに達しました。時間をおいて再度お試しください。"
    when /key/i
      "APIキーが設定されていません。管理者に連絡してください。"
    else
      "検索中にエラーが発生しました。（#{error.class}）"
    end
  end
end
