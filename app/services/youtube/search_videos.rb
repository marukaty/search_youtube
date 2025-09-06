require "faraday"
require "json"

module Youtube
  class SearchVideos
    ENDPOINT = "https://www.googleapis.com/youtube/v3/search"

    def self.call(query:, limit: 10)
      new(query, limit).call
    end

    def initialize(query, limit)
      @query = query.to_s.strip
      @limit = [ [ limit.to_i, 1 ].max, 50 ].min
      @api_key = Rails.application.credentials.dig(:google, :api_key)
    end

    def call
      raise "YouTube APIキーが設定されていません" if @api_key.blank?
      raise ArgumentError, "検索クエリを指定してください" if @query.blank?

      get_video_data
    end

    private

    def get_video_data
      raise "YouTube APIエラー (#{response.status})" unless response.success?

      body = JSON.parse(response.body)
      Array(body["items"]).map { |item| format_item(item) }
    end

    def connection
      @connecton ||= Faraday.new("https://www.googleapis.com") { |f| f.adapter :net_http }
    end

    def response
      @response ||= connection.get(ENDPOINT, {
                      part: "snippet",
                      q: @query,
                      type: "video",
                      order: "viewCount",
                      maxResults: @limit,
                      key: Rails.application.credentials.dig(:google, :api_key)
                    })
    end

    def format_item(item)
      vid = item.dig("id", "videoId")
      sn  = item["snippet"] || {}
      cid = sn["channelId"]
      th  = sn["thumbnails"] || {}
      {
        channel_name:  sn["channelTitle"],
        channel_url:   "https://www.youtube.com/channel/#{cid}",
        video_url:     "https://www.youtube.com/watch?v=#{vid}",
        thumbnail_url: th.dig("high", "url") || th.dig("default", "url"),
        published_at:  sn["publishedAt"]
      }
    end
  end
end
