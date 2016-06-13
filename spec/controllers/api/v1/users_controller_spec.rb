describe Api::V1::UsersController, :show_in_doc do
  let(:user) { create :user, nickname: 'Test' }

  describe '#index' do
    let!(:user_1) { create :user, nickname: 'Test1' }
    let!(:user_2) { create :user, nickname: 'Test2' }
    let!(:user_3) { create :user, nickname: 'Test3' }

    before { get :index, page: 1, limit: 1, search: 'Te', format: :json }

    it do
      expect(response).to have_http_status :success
      expect(response.content_type).to eq 'application/json'
      expect(collection).to have(2).items
    end
  end

  describe '#show' do
    before { get :show, id: user.id, format: :json }

    it do
      expect(json).to_not have_key :email
      expect(response).to have_http_status :success
      expect(response.content_type).to eq 'application/json'
    end
  end

  describe '#info' do
    before { get :info, id: user.id, format: :json }

    it do
      expect(response).to have_http_status :success
      expect(response.content_type).to eq 'application/json'
    end
  end

  describe '#whoami' do
    describe 'signed_in' do
      before { sign_in user }
      before { get :whoami, format: :json }

      it { expect(response).to have_http_status :success }

      context 'json' do
        subject { OpenStruct.new JSON.parse(response.body) }
        its(:id) { should eq user.id }
        its(:nickname) { should eq user.nickname }
      end
    end

    describe 'guest' do
      before { get :whoami, format: :json }
      specify { expect(response.body).to eq 'null' }
    end unless ENV['APIPIE_RECORD']
  end

  describe '#friends' do
    let(:user) { create :user, friends: [create(:user)] }

    before { get :friends, id: user.id, format: :json }
    it { expect(response).to have_http_status :success }
  end

  describe '#anime_rates' do
    let(:user) { create :user }
    let(:anime) { create :anime }
    let!(:user_rate) { create :user_rate, target: anime, user: user, status: 1 }

    before { get :anime_rates, id: user.id, status: 1, limit: 250, page: 1, format: :json }

    it do
      expect(response).to have_http_status :success
      expect(assigns(:rates)).to have(1).item
    end
  end

  describe '#manga_rates' do
    let(:user) { create :user }
    let(:manga) { create :manga }
    let!(:user_rate) { create :user_rate, target: manga, user: user, status: 1 }
    before { get :manga_rates, id: user.id, status: 1, limit: 250, page: 1, format: :json }

    it do
      expect(response).to have_http_status :success
      expect(assigns(:rates)).to have(1).item
    end
  end

  describe '#clubs' do
    let(:user) { create :user, clubs: [create(:club)] }

    before { get :clubs, id: user.id, format: :json }
    it { expect(response).to have_http_status :success }
  end

  describe '#favourites' do
    let(:user) { seed :user }
    let(:anime) { create :anime }
    let(:manga) { create :manga }
    let(:character) { create :character }
    let(:person) { create :person }
    let!(:fav_anime) { create :favourite, linked: anime }
    let!(:fav_manga) { create :favourite, linked: manga }
    let!(:fav_character) { create :favourite, linked: character }
    let!(:fav_person) { create :favourite, linked: person, kind: Favourite::Person }
    let!(:fav_mangaka) { create :favourite, linked: person, kind: Favourite::Mangaka }
    let!(:fav_producer) { create :favourite, linked: person, kind: Favourite::Producer }
    let!(:fav_seyu) { create :favourite, linked: person, kind: Favourite::Seyu }

    before { get :favourites, id: user.id, format: :json }
    it { expect(response).to have_http_status :success }
  end

  describe '#messages' do
    let(:user_2) { create :user }
    let(:topic) { create :news_topic, linked: create(:anime), action: 'episode' }
    let!(:news) { create :message, kind: MessageType::Anons, to: user, from: user_2, body: 'anime [b]anons[/b]', linked: topic }

    context 'signed_in' do
      before { sign_in user }
      before { get :messages, id: user.id, page: 1, limit: 20, type: 'news', format: :json }
      it { expect(response).to have_http_status :success }
    end

    context 'guest' do
      before { get :messages, id: user.id, page: 1, limit: 20, type: 'news', format: :json }
      it { should respond_with 401 }
    end unless ENV['APIPIE_RECORD']
  end

  describe '#unread_messages' do
    context 'signed_in' do
      before { sign_in user }
      before { get :unread_messages, id: user.id, format: :json }
      it { expect(response).to have_http_status :success }
    end

    context 'guest' do
      before { get :unread_messages, id: user.id, format: :json }
      it { should respond_with 401 }
    end unless ENV['APIPIE_RECORD']
  end

  describe '#history' do
    let!(:entry_1) { create :user_history, user: user, action: 'mal_anime_import', value: '522' }
    let!(:entry_2) { create :user_history, target: create(:anime), user: user, action: 'status' }

    describe 'index' do
      before { get :history, id: user.id, limit: 10, page: 1, format: :json }
      it { expect(response).to have_http_status :success }
    end
  end

  describe '#bans' do
    let!(:ban) { create :ban, user: user, moderator: user, comment: create(:comment, user: user) }
    before { get :bans, id: user.id, format: :json }

    it do
      expect(collection).to have(1).item
      expect(response).to have_http_status :success
    end
  end

  describe '#anime_video_reports' do
    let!(:anime_video_report) { create :anime_video_report, user: user, anime_video: anime_video }
    let(:anime_video) { create :anime_video }
    before { get :anime_video_reports, id: user.id, page: 1, limit: 1, format: :json }

    it do
      expect(collection).to have(1).item
      expect(response).to have_http_status :success
    end
  end
end
