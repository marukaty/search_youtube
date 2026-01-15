require 'rails_helper'

RSpec.describe Youtube::SearchVideos do
  describe '#call' do
    let(:api_key) { 'test_api_key' }
    let(:params) do
      {
        q: 'Ruby on Rails',
        limit: 10,
        sort: 'viewCount',
        published_after: 1.month.ago,
        published_before: Time.now
      }
    end

    before do
      allow(Rails.application.credentials).to receive(:dig).with(:google, :api_key).and_return(api_key)
    end

    it '正常に動画データを取得できること' do
      # search API のモックレスポンス
      search_response = {
        items: [
          {
            id: { videoId: 'video123' },
            snippet: {
              title: 'Ruby Tutorial',
              channelTitle: 'Tech Channel',
              channelId: 'channel123',
              publishedAt: '2025-10-01T00:00:00Z',
              thumbnails: {
                high: { url: 'https://example.com/high.jpg' },
                default: { url: 'https://example.com/default.jpg' }
              }
            }
          }
        ]
      }
      # statistics API のモックレスポンス
      statistics_response = {
        items: [
          {
            id: 'video123',
            statistics: { viewCount: '150000' }
          }
        ]
      }

      allow_any_instance_of(Faraday::Connection).to receive(:get).and_call_original
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with('https://www.googleapis.com/youtube/v3/search', anything)
        .and_return(double(body: search_response.to_json))
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with('https://www.googleapis.com/youtube/v3/videos', anything)
        .and_return(double(body: statistics_response.to_json))

      result = described_class.call(params)

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first).to include(
        channel_name: 'Tech Channel',
        channel_url: 'https://www.youtube.com/channel/channel123',
        video_url: 'https://www.youtube.com/watch?v=video123',
        thumbnail_url: 'https://example.com/high.jpg',
        published_at: '2025-10-01T00:00:00Z',
        view_count: 150000
      )
    end
  end
end
