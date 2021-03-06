require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

module Clockwork
  every(5.minutes, 'pghero.query_stats') { PgHero.capture_query_stats }
  every(1.day, 'pghero.space_stats', at: '00:45') { PgHero.capture_space_stats }

  every 10.minutes, 'history.toshokan' do
    HistoryWorker.perform_async
    ImportToshokanTorrents.perform_async true
    # ImportNyaaTorrents.perform_async
    # ProxyWorker.perform_async(true)
    SidekiqHeartbeat.new.perform
  end

  every 30.minutes, 'half-hourly.import', at: ['**:15', '**:45'] do
    MalParsers::FetchPage.perform_async 'anime', 'updated_at', 0, 3
    MalParsers::FetchPage.perform_async 'manga', 'updated_at', 0, 5

    MalParsers::RefreshEntries.perform_async 'anime', 'anons', 12.hours
    MalParsers::RefreshEntries.perform_async 'anime', 'ongoing', 8.hours
    MalParsers::ScheduleExpired.perform_async 'anime'
  end

  every 30.minutes, 'half-hourly.import.another', at: ['**:00', '**:30'] do
    PostgresFix.perform_async
  end

  every 1.hour, 'hourly', at: '**:45' do
    ProxyWorker.perform_async(false)
    # FindAnimeWorker.perform_async :last_3_entries
    # AnimeSpiritWorker.perform_async :last_3_entries
    BadReviewsCleaner.perform_async
  end

  # every 1.day, 'find anime imports', at: ['01:00', '07:00', '13:00', '19:00'] do
    # FindAnimeWorker.perform_async :last_15_entries
    # HentaiAnimeWorker.perform_async :last_15_entries
    # AnimeSpiritWorker.perform_async :two_pages
  # end

  every 1.day, 'daily.stuff', at: '00:02' do
    ImportAnimeCalendars.perform_async
  end

  every 1.day, 'daily.stuff', at: '00:30' do
    MalParsers::ScheduleExpired.perform_async 'manga'
    MalParsers::ScheduleExpired.perform_async 'character'
    MalParsers::ScheduleExpired.perform_async 'person'
    MalParsers::ScheduleMissingPersonRoles.perform_async 'character'
    MalParsers::ScheduleMissingPersonRoles.perform_async 'person'

    SakuhindbImporter.perform_async with_fail: false

    # AnimeLinksVerifier.perform_async

    FinishExpiredAnimes.perform_async

    # AutobanFix.perform_async

    MalParsers::ScheduleExpiredAuthorized.perform_async
  end

  every 1.day, 'daily.long-stuff', at: '03:00' do
    MalParsers::RefreshEntries.perform_async 'anime', 'latest', 1.week
    # SubtitlesImporter.perform_async :ongoings
    ImagesVerifier.perform_async
    AnimeOnline::FixAnimeVideoAuthors.perform_async
    AnimeOnline::CleanupAnimeVideos.perform_async
    # Users::CleanupDoorkeeperTokens.perform_async
  end

  every 1.day, 'daily.torrents-check', at: '03:00' do
    ImportToshokanTorrents.perform_async false
  end

  every 1.day, 'daily.contests', at: '03:38' do
    Contests::Progress.perform_async
  end

  # every 1.day, 'daily.mangas', at: '04:00' do
    # ReadMangaWorker.perform_async
    # AdultMangaWorker.perform_async
  # end

  every 1.day, 'daily.viewings_cleaner', at: '05:00' do
    ViewingsCleaner.perform_async
  end

  every 1.week, 'weekly.stuff.1', at: 'Monday 00:45' do
    Anidb::ImportDescriptionsJob.perform_async
    # FindAnimeWorker.perform_async :first_page
  end

  every 1.week, 'weekly.stuff.2', at: 'Monday 01:45' do
    # FindAnimeWorker.perform_async :two_pages
    # HentaiAnimeWorker.perform_async :first_page
    DanbooruTagsImporter.perform_async
    OldMessagesCleaner.perform_async
    OldNewsCleaner.perform_async
    UserImagesCleaner.perform_async
    SakuhindbImporter.perform_async with_fail: true
    # SubtitlesImporter.perform_async :latest
    BadVideosCleaner.perform_async
    CleanupScreenshots.perform_async

    MalParsers::FetchPage.perform_async 'anime', 'updated_at', 0, 100
    MalParsers::FetchPage.perform_async 'manga', 'updated_at', 0, 100

    PeopleJobsActualzier.perform_async
  end

  every 1.week, 'weekly.stuff.3', at: 'Monday 02:45' do
    DbEntries::UpdateCachedRatesCounts.perform_async

    AnimesVerifier.perform_async
    MangasVerifier.perform_async
    CharactersVerifier.perform_async
    PeopleVerifier.perform_async
  end

  # every 1.week, 'weekly.vacuum', at: 'Monday 05:00' do
    # VacuumDb.perform_async
  # end

  every 1.week, 'weekly.stuff.4', at: 'Monday 05:45' do
    NameMatches::Refresh.perform_async Anime.name
  end

  every 1.week, 'weekly.stuff.5', at: 'Monday 06:15' do
    NameMatches::Refresh.perform_async Manga.name
  end

  every 1.day, 'monthly.vacuum', at: '05:00', if: lambda { |t| t.day == 28 } do
    VacuumDb.perform_async
  end
end
