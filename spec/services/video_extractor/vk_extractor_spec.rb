describe VideoExtractor::VkExtractor, vcr: { cassette_name: 'vk_extractor' } do
  let(:service) { described_class.new url }

  describe '#fetch' do
    subject { service.fetch }

    context 'valid_url' do
      context 'common' do
        let(:url) { 'http://vk.com/video98023184_165811692' }

        its(:hosting) { is_expected.to eq 'vk' }
        its(:image_url) { is_expected.to eq '//pp.userapi.com/c514511/u98023184/video/l_81cce630.jpg' }
        its(:player_url) { is_expected.to eq '//vk.com/video_ext.php?oid=98023184&id=165811692&hash=6d9a4c5f93270892' }
      end

      context 'dash' do
        let(:url) { 'http://vk.com/video-42313379_167267838' }
        its(:hosting) { is_expected.to eq 'vk' }
      end

      context 'params' do
        let(:url) { 'https://vk.com/video-61933528_167061553?hash=w4ertfg' }
        its(:hosting) { is_expected.to eq 'vk' }
      end
    end

    context 'invalid_url' do
      let(:url) { 'http://vk.com/video98023184_165811692zzz' }
      it { is_expected.to be_nil }
    end

    context 'private_url' do
      let(:url) { 'http://vk.com/video17174270_167070090' }
      it { is_expected.to be_nil }
    end

    context 'video_with_authorization_url' do
      let(:url) { 'https://vk.com/video-26094363_159977945' }
      it { is_expected.to be_nil }
    end
  end

  describe '.normalize_url' do
    subject { described_class.normalize_url url }
    let(:url) { 'http://vkontakte.ru/video17174270_167070090' }

    it { is_expected.to eq 'https://vk.com/video17174270_167070090' }
  end
end
