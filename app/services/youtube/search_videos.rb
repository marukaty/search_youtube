require "faraday"
require "json"

module Youtube
  class SearchVideos
    CHANNEL_ENDPOINT = "https://www.googleapis.com/youtube/v3/search"
    VIDEOS_ENDPOINT = "https://www.googleapis.com/youtube/v3/videos"
    ALLOWED_ORDERS  = %w[date viewCount relevance].freeze

    class << self
      def call(params)
        new(params).call
      end
    end

    def initialize(params)
      origin_limit = params[:limit].presence&.to_i || 10
      after = params[:published_after]&.to_time || Time.now.ago(1.months)
      before = params[:published_before]&.to_time || Time.now

      @query = params[:q].to_s.strip
      @limit = [ [ origin_limit.to_i, 1 ].max, 50 ].min
      @order  = ALLOWED_ORDERS.include?(params[:sort]) ? params[:sort] : "viewCount"
      @published_after = after.utc.iso8601
      @published_before = before.utc.iso8601
      @api_key = Rails.application.credentials.dig(:google, :api_key)
    end

    def call
      raise "YouTube APIキーが設定されていません" if @api_key.blank?
      raise ArgumentError, "検索クエリを指定してください" if @query.blank?

      get_video_data
    end

    private

    def get_video_data
      body = JSON.parse(channel_response.body)
      video_ids = body["items"].map { |it| it.dig("id", "videoId") }.compact
      Array(body["items"]).map { |item| format_item(item, fetch_statistics(video_ids)) }
    end

    def connection
      @connecton ||= Faraday.new("https://www.googleapis.com") { |f| f.adapter :net_http }
    end

    def channel_response
      @channel_response ||= connection.get(CHANNEL_ENDPOINT, {
                                                              part: "snippet",
                                                              q: @query,
                                                              type: "video",
                                                              order: @order,
                                                              maxResults: @limit,
                                                              key: @api_key,
                                                              publishedBefore: @published_before,
                                                              publishedAfter: @published_after
                                                            })
    end

    def video_response(video_ids)
      @video_response ||= connection.get(VIDEOS_ENDPOINT, {
                                        part: "statistics",
                                        id: video_ids.join(","),
                                        key: @api_key
                                      })
    end

    def fetch_statistics(video_ids)
      body = JSON.parse(video_response(video_ids).body)
      @fetch_statistics ||= Hash[
                              Array(body["items"]).map do |it|
                                [ it["id"], it.dig("statistics", "viewCount").to_i ]
                              end
                            ]
    end

    def format_item(item, stats_by_id)
      vid = item.dig("id", "videoId")
      sn  = item["snippet"] || {}
      cid = sn["channelId"]
      th  = sn["thumbnails"] || {}
      {
        title:         sn["title"],
        channel_name:  sn["channelTitle"],
        channel_url:   "https://www.youtube.com/channel/#{cid}",
        video_url:     "https://www.youtube.com/watch?v=#{vid}",
        thumbnail_url: th.dig("high", "url") || th.dig("default", "url"),
        published_at:  sn["publishedAt"],
        view_count:    stats_by_id[vid] || 0
      }
    end
  end
end
