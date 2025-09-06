class SearchVideosController < ApplicationController
  def index
    @q = params[:q].to_s.strip
    @limit = params[:limit].presence&.to_i || 10

    @videos = []
    return if @q.blank?

    @videos = Youtube::SearchVideos.call(query: @q, limit: @limit)
  rescue StandardError => e
    Rails.logger.warn("[videos#index] #{e.class}: #{e.message}")
    flash.now[:alert] = user_friendly_message(e)
    @videos = []
  end

  private

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
