require 'rails_helper'

RSpec.describe 'YouTube検索画面', type: :system do
  before do
    # APIレスポンスのモック
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
    statistics_response = {
      items: [
        {
          id: 'video123',
          statistics: { viewCount: '150000' }
        }
      ]
    }

    allow(Rails.application.credentials).to receive(:dig).with(:google, :api_key).and_return('test_api_key')
    allow_any_instance_of(Faraday::Connection).to receive(:get).and_call_original
    allow_any_instance_of(Faraday::Connection).to receive(:get)
      .with('https://www.googleapis.com/youtube/v3/search', anything)
      .and_return(double(body: search_response.to_json))
    allow_any_instance_of(Faraday::Connection).to receive(:get)
      .with('https://www.googleapis.com/youtube/v3/videos', anything)
      .and_return(double(body: statistics_response.to_json))
  end

  it 'フォームに値を入力して検索し、動画データが表示されること' do
    browser = Capybara.current_session.driver.browser
    browser.manage.window.resize_to(1280, 800)
    visit search_videos_path

    fill_in 'キーワード', with: 'Ruby on Rails'
    select '10', from: 'search_limit'
    execute_script("document.getElementById('search_published_after').value = '2025-09-01'")
    execute_script("document.getElementById('search_published_before').value = '2025-11-01'")
    click_button '検索'

    expect(page).to have_content('Tech Channel')
    expect(page).to have_content('Ruby Tutorial')
    expect(page).to have_content('2025/10/01 09:00')
    expect(page).to have_content('15万回')
    expect(page).to have_selector("img[src='https://example.com/high.jpg']")
  end
end
