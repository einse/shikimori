describe VideoExtractor::OpenGraphExtractor, vcr: { cassette_name: 'open_graph_video' } do
  let(:service) { VideoExtractor::OpenGraphExtractor.new url }

  describe '#fetch' do
    subject { service.fetch }

    context 'twitch' do
      context do
        let(:url) { 'http://www.twitch.tv/joindotared/c/3661348' }

        its(:hosting) { is_expected.to eq 'twitch' }
        its(:image_url) { is_expected.to eq '//static-cdn.jtvnw.net/jtv_user_pictures/joindotared-profile_image-3280e012c28e251e-600x600.jpeg' }
        its(:player_url) { is_expected.to eq '//www-cdn.jtvnw.net/swflibs/TwitchPlayer.swf?channel=joindotared&playerType=facebook' }
      end

      context do
        let(:url) { 'https://www.twitch.tv/videos/168874638' }

        its(:hosting) { is_expected.to eq 'twitch' }
        its(:image_url) { is_expected.to eq '//static-cdn.jtvnw.net/s3_vods/f5d8e3520fc389dac129_pterotactical_26073628016_698271942//thumb/thumb168874638-480x320.jpg' }
        its(:player_url) { is_expected.to eq '//player.twitch.tv/?video=v168874638&player=twitter&autoplay=false' }
      end
    end

    context 'myvi' do
      let(:url) { 'http://asia.myvi.ru/watch/Vojna-Magov_eQ4now9R-0KG9eoESX_N-A2' }

      its(:hosting) { is_expected.to eq 'myvi' }
      its(:image_url) { is_expected.to eq '//images.myvi.ru/animeicon/25/e6/58917.jpg' }
      its(:player_url) { is_expected.to eq '//myvi.ru/player/flash/oI_SgyRHWdMLI6UU2pmRESiY4Y-Ie0wAnu3jBetGxgY9wJFPgg4yJA4JzsT1kQ7a35LOr3hG3K7g1' }
    end

    context 'sibnet' do
      let(:url) { 'http://video.sibnet.ru/video1234982-03__Poverivshiy_v_grezyi' }

      its(:hosting) { is_expected.to eq 'sibnet' }
      its(:image_url) { is_expected.to eq '//video.sibnet.ru/upload/cover/video_1234982_0.jpg' }
      its(:player_url) { is_expected.to eq '//video.sibnet.ru/shell.php?videoid=1234982' }

      context 'broken_video' do
        let(:url) { 'http://video.sibnet.ru/video996603-Kyou_no_Asuka_Show_1_5_serii__rus__sub_' }
        it { is_expected.to be_nil }
      end
    end

    # context 'yandex' do
      # let(:url) { 'http://video.yandex.ru/users/allod2008/view/78' }

      # its(:hosting) { is_expected.to eq 'yandex' }
      # its(:image_url) { is_expected.to eq 'http://static.video.yandex.ru/get/allod2008/khubzhabwp.1610/m320x240.jpg' }
      # its(:player_url) { is_expected.to eq 'http://static.video.yandex.ru/full-10/allod2008/khubzhabwp.1610/player.swf' }
    # end

    context 'streamable' do
      let(:url) { 'https://streamable.com/efgm' }

      its(:hosting) { is_expected.to eq 'streamable' }
      its(:image_url) { is_expected.to eq '//cdn.streamable.com/image/efgm.jpg' }
      its(:player_url) { is_expected.to eq '//streamable.com/e/efgm' }
    end

    context 'invalid_url' do
      let(:url) { 'http://coub.cOOOm/view/bqn2pda' }
      it { is_expected.to be_nil }
    end
  end
end
