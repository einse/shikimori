# frozen_string_literal: true

describe AnimeVideoAuthor::Rename do
  let!(:anime_video) { create :anime_video, author: author_1 }
  let!(:author_1) { create :anime_video_author, name: 'zxc' }
  let!(:author_2) { create :anime_video_author, name: 'vbn' }

  subject! { AnimeVideoAuthor::Rename.call author_1, new_name }

  context 'no name' do
    let(:new_name) { '' }

    it do
      expect { author_1.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(anime_video.reload.author_name).to be_nil
    end
  end

  context 'another author name' do
    let(:new_name) { 'vbn' }

    it do
      expect { author_1.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(anime_video.reload.author_name).to eq author_2.name
    end
  end

  context 'just new name' do
    let(:new_name) { '123' }

    it do
      expect(author_1.reload.name).to eq new_name
      expect(anime_video.reload.author_name).to eq author_1.name
    end
  end

  context 'no changes in name' do
    let(:new_name) { author_1.name }

    it do
      expect(author_1.reload.name).to eq new_name
      expect(anime_video.reload.author_name).to eq author_1.name
    end
  end
end
