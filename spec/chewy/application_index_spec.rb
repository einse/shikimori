describe ApplicationIndex, :vcr do
  before do
    # VCR.configure { |c| c.ignore_request { |_request| true } }
    # Chewy.logger = ActiveSupport::Logger.new(STDOUT)
    # Chewy.transport_logger = ActiveSupport::Logger.new(STDOUT)
    ActiveRecord::Base.connection.reset_pk_sequence! :users
    ClubsIndex.purge!
  end

  let(:url) do
    'http://localhost:9200/shikimori_test_clubs/_analyze'\
      "?analyzer=#{analyzer}"\
      "&text=#{CGI.escape text}"
  end
  let(:response) { open(url).read }

  let(:text) { 'Kai wa-sama' }

  subject do
    JSON.parse(response, symbolize_names: true)[:tokens].map do |entry|
      entry[:token]
    end
  end

  context 'original_analyzer' do
    let(:analyzer) { :original_analyzer }

    it do
      is_expected.to eq [
        'kai wa-sama'
      ]
    end
  end

  context 'edge_phrase_analyzer' do
    let(:analyzer) { :edge_phrase_analyzer }

    it do
      is_expected.to eq [
        'k',
        'ka',
        'kai',
        'kai ',
        'kai w',
        'kai wa',
        'kai wa-',
        'kai wa-s',
        'kai wa-sa',
        'kai wa-sam',
        'kai wa-sama'
      ]
    end

    context 'one word' do
      let(:text) { 'test' }
      it { is_expected.to eq %w[t te tes test] }
    end

    context 'two words' do
      let(:text) { 'te st' }
      it do
        is_expected.to eq [
          't',
          'te',
          'te ',
          'te s',
          'te st'
        ]
      end
    end

    context 'same words' do
      let(:text) { 'tes tes' }
      it do
        is_expected.to eq [
          't',
          'te',
          'tes',
          'tes ',
          'tes t',
          'tes te',
          'tes tes'
        ]
      end
    end
  end

  context 'edge_word_analyzer' do
    let(:analyzer) { :edge_word_analyzer }

    it do
      is_expected.to eq [
        'k',
        'ka',
        'kai',
        'w',
        'wa',
        's',
        'sa',
        'sam',
        'sama'
      ]
    end

    context 'one word' do
      let(:text) { 'test' }
      it { is_expected.to eq %w[t te tes test] }
    end

    context 'two words' do
      let(:text) { 'te st' }
      it { is_expected.to eq %w[t te s st] }
    end

    context 'same words' do
      let(:text) { 'tes tes' }
      it { is_expected.to eq %w[t te tes t te tes] }
    end
  end

  context 'ngram_analyzer' do
    let(:analyzer) { :ngram_analyzer }

    it do
      is_expected.to eq [
        'k',
        'ka',
        'kai',
        'a',
        'ai',
        'i',
        'w',
        'wa',
        'a',
        's',
        'sa',
        'sam',
        'sama',
        'a',
        'am',
        'ama',
        'm',
        'ma'
      ]
    end

    context 'one word' do
      let(:text) { 'test' }
      it { is_expected.to eq %w[t te tes test e es est s st] }
    end

    context 'two words' do
      let(:text) { 'te st' }
      it { is_expected.to eq %w[t te e s st t] }
    end

    context 'same words' do
      let(:text) { 'tes tes' }
      it { is_expected.to eq %w[t te tes e es s t te tes e es s] }
    end
  end

  context 'search_analyzer' do
    let(:analyzer) { :search_analyzer }

    it do
      is_expected.to eq [
        'kai',
        'wa',
        'sama'
      ]
    end

    context 'one word' do
      let(:text) { 'test' }
      it { is_expected.to eq %w[test] }
    end

    context 'two words' do
      let(:text) { 'te st' }
      it { is_expected.to eq %w[te st] }
    end

    context 'same words' do
      let(:text) { 'tes tes' }
      it { is_expected.to eq %w[tes tes] }
    end
  end
end