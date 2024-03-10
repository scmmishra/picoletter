require "test_helper"

class NewslettersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get newsletters_show_url
    assert_response :success
  end
end
