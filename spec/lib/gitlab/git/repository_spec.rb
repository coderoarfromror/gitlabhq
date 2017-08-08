  include Gitlab::EncodingHelper
  shared_examples 'wrapping gRPC errors' do |gitaly_client_class, gitaly_client_method|
    it 'wraps gRPC not found error' do
      expect_any_instance_of(gitaly_client_class).to receive(gitaly_client_method)
        .and_raise(GRPC::NotFound)
      expect { subject }.to raise_error(Gitlab::Git::Repository::NoRepository)
    end

    it 'wraps gRPC unknown error' do
      expect_any_instance_of(gitaly_client_class).to receive(gitaly_client_method)
        .and_raise(GRPC::Unknown)
      expect { subject }.to raise_error(Gitlab::Git::CommandError)
    end
  end

  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH) }
  describe '#root_ref' do
    context 'with gitaly disabled' do
      before do
        allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(false)
      end

      it 'calls #discover_default_branch' do
        expect(repository).to receive(:discover_default_branch)
        repository.root_ref
      end
    end

    it 'returns UTF-8' do
      expect(repository.root_ref).to be_utf8
    end

    it 'gets the branch name from GitalyClient' do
      expect_any_instance_of(Gitlab::GitalyClient::Ref).to receive(:default_branch_name)
      repository.root_ref
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::Ref, :default_branch_name do
      subject { repository.root_ref }
    end
  end

  describe "#rugged" do
    context 'with no Git env stored' do
      before do
        expect(Gitlab::Git::Env).to receive(:all).and_return({})
      end

      it "whitelist some variables and pass them via the alternates keyword argument" do
        expect(Rugged::Repository).to receive(:new).with(repository.path, alternates: [])

        repository.rugged
      end
    end

    context 'with some Git env stored' do
      before do
        expect(Gitlab::Git::Env).to receive(:all).and_return({
          'GIT_OBJECT_DIRECTORY' => 'foo',
          'GIT_ALTERNATE_OBJECT_DIRECTORIES' => 'bar',
          'GIT_OTHER' => 'another_env'
        })
      end

      it "whitelist some variables and pass them via the alternates keyword argument" do
        expect(Rugged::Repository).to receive(:new).with(repository.path, alternates: %w[foo bar])

        repository.rugged
      end
    end
  end

  describe '#branch_names' do

    it 'returns UTF-8' do
      expect(subject.first).to be_utf8
    end


    it 'gets the branch names from GitalyClient' do
      expect_any_instance_of(Gitlab::GitalyClient::Ref).to receive(:branch_names)
      subject
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::Ref, :branch_names
  describe '#tag_names' do

    it 'returns UTF-8' do
      expect(subject.first).to be_utf8
    end


    it 'gets the tag names from GitalyClient' do
      expect_any_instance_of(Gitlab::GitalyClient::Ref).to receive(:tag_names)
      subject
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::Ref, :tag_names
  describe '#archive_prefix' do
    let(:project_name) { 'project-name'}

    before do
      expect(repository).to receive(:name).once.and_return(project_name)
    end

    it 'returns parameterised string for a ref containing slashes' do
      prefix = repository.archive_prefix('test/branch', 'SHA')

      expect(prefix).to eq("#{project_name}-test-branch-SHA")
    end

    it 'returns correct string for a ref containing dots' do
      prefix = repository.archive_prefix('test.branch', 'SHA')

      expect(prefix).to eq("#{project_name}-test.branch-SHA")
    end
  end

  describe '#archive' do
  describe '#archive_zip' do
  describe '#archive_bz2' do
  describe '#archive_fallback' do
  describe '#size' do
  describe '#has_commits?' do
  describe '#empty?' do
  describe '#bare?' do
  describe '#heads' do
  describe '#ref_names' do
  describe '#search_files' do
  describe '#submodule_url_for' do
    let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH) }
    let(:ref) { 'master' }

    def submodule_url(path)
      repository.submodule_url_for(ref, path)
    end

    it { expect(submodule_url('six')).to eq('git://github.com/randx/six.git') }
    it { expect(submodule_url('nested/six')).to eq('git://github.com/randx/six.git') }
    it { expect(submodule_url('deeper/nested/six')).to eq('git://github.com/randx/six.git') }
    it { expect(submodule_url('invalid/path')).to eq(nil) }

    context 'uncommitted submodule dir' do
      let(:ref) { 'fix-existing-submodule-dir' }

      it { expect(submodule_url('submodule-existing-dir')).to eq(nil) }
    end

    context 'tags' do
      let(:ref) { 'v1.2.1' }

      it { expect(submodule_url('six')).to eq('git://github.com/randx/six.git') }
    end

    context 'no submodules at commit' do
      let(:ref) { '6d39438' }

      it { expect(submodule_url('six')).to eq(nil) }
    end
  end

  context '#submodules' do
    let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH) }
      let(:submodules) { repository.send(:submodules, 'master') }
            "name" => "six",
        expect(nested['name']).to eq('nested/six')
        expect(nested['name']).to eq('deeper/nested/six')
        submodules = repository.send(:submodules, 'fix-existing-submodule-dir')
        submodules = repository.send(:submodules, 'v1.2.1')
            "name" => "six",

      it 'should not break on invalid syntax' do
        allow(repository).to receive(:blob_content).and_return(<<-GITMODULES.strip_heredoc)
          [submodule "six"]
          path = six
          url = git://github.com/randx/six.git

          [submodule]
          foo = bar
        GITMODULES

        expect(submodules).to have_key('six')
      end
      let(:submodules) { repository.send(:submodules, '6d39438') }
  describe '#commit_count' do
    shared_examples 'counting commits' do
      it { expect(repository.commit_count("master")).to eq(25) }
      it { expect(repository.commit_count("feature")).to eq(9) }
    end

    context 'when Gitaly commit_count feature is enabled' do
      it_behaves_like 'counting commits'
      it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::Commit, :commit_count do
        subject { repository.commit_count('master') }
      end
    end

    context 'when Gitaly commit_count feature is disabled', skip_gitaly_mock: true  do
      it_behaves_like 'counting commits'
    end
    change_path = File.join(SEED_STORAGE_PATH, TEST_NORMAL_REPO_PATH, "CHANGELOG")
    untracked_path = File.join(SEED_STORAGE_PATH, TEST_NORMAL_REPO_PATH, "UNTRACKED")
    tracked_path = File.join(SEED_STORAGE_PATH, TEST_NORMAL_REPO_PATH, "files", "ruby", "popen.rb")
        @normal_repo = Gitlab::Git::Repository.new('default', TEST_NORMAL_REPO_PATH)
        new_tip = @normal_repo.rugged.references["refs/heads/master"]
          .target.oid
        @normal_repo = Gitlab::Git::Repository.new('default', TEST_NORMAL_REPO_PATH)
          normal_repo = Gitlab::Git::Repository.new('default', TEST_NORMAL_REPO_PATH)
          @normal_repo = Gitlab::Git::Repository.new('default', TEST_NORMAL_REPO_PATH)
          File.open(File.join(SEED_STORAGE_PATH, TEST_NORMAL_REPO_PATH, ".gitignore"), "r") do |f|
          FileUtils.rm_rf(SEED_STORAGE_PATH, TEST_NORMAL_REPO_PATH)
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.remote_add("new_remote", SeedHelper::GITLAB_GIT_TEST_REPO_URL)
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
    before(:context) do
      repo = Gitlab::Git::Repository.new('default', TEST_REPO_PATH).rugged
    after(:context) do
      # Erase our commits so other tests get the original repo
      repo = Gitlab::Git::Repository.new('default', TEST_REPO_PATH).rugged
      repo.references.update("refs/heads/master", SeedRepo::LastCommit::ID)
    end

      let(:options) { { ref: "master", follow: true } }
        it "does not follow renames" do
          log_commits = repository.log(options.merge(path: "encoding"))
          aggregate_failures do
            expect(log_commits).to include(commit_with_new_name)
            expect(log_commits).to include(rename_commit)
            expect(log_commits).not_to include(commit_with_old_name)
          end
        context 'without offset' do
          it "follows renames" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG"))

            aggregate_failures do
              expect(log_commits).to include(commit_with_new_name)
              expect(log_commits).to include(rename_commit)
              expect(log_commits).to include(commit_with_old_name)
            end
          end
        context 'with offset=1' do
          it "follows renames and skip the latest commit" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 1))

            aggregate_failures do
              expect(log_commits).not_to include(commit_with_new_name)
              expect(log_commits).to include(rename_commit)
              expect(log_commits).to include(commit_with_old_name)
            end
          end
        end

        context 'with offset=1', 'and limit=1' do
          it "follows renames, skip the latest commit and return only one commit" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 1, limit: 1))

            expect(log_commits).to contain_exactly(rename_commit)
          end
        end

        context 'with offset=1', 'and limit=2' do
          it "follows renames, skip the latest commit and return only two commits" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 1, limit: 2))

            aggregate_failures do
              expect(log_commits).to contain_exactly(rename_commit, commit_with_old_name)
            end
          end
        end

        context 'with offset=2' do
          it "follows renames and skip the latest commit" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 2))

            aggregate_failures do
              expect(log_commits).not_to include(commit_with_new_name)
              expect(log_commits).not_to include(rename_commit)
              expect(log_commits).to include(commit_with_old_name)
            end
          end
        end

        context 'with offset=2', 'and limit=1' do
          it "follows renames, skip the two latest commit and return only one commit" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 2, limit: 1))

            expect(log_commits).to contain_exactly(commit_with_old_name)
          end
        end

        context 'with offset=2', 'and limit=2' do
          it "follows renames, skip the two latest commit and return only one commit" do
            log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 2, limit: 2))

            aggregate_failures do
              expect(log_commits).not_to include(commit_with_new_name)
              expect(log_commits).not_to include(rename_commit)
              expect(log_commits).to include(commit_with_old_name)
            end
          end
        it "does not follow renames" do
          log_commits = repository.log(options.merge(path: "CHANGELOG"))
          aggregate_failures do
            expect(log_commits).not_to include(commit_with_new_name)
            expect(log_commits).to include(rename_commit)
            expect(log_commits).to include(commit_with_old_name)
          end
        it "returns an empty array" do
          log_commits = repository.log(options.merge(ref: 'unknown'))
        expect(commits).to satisfy do |commits|
          commits.all? { |commit| commit.time >= options[:after] }
        expect(commits).to satisfy do |commits|
          commits.all? { |commit| commit.time <= options[:before] }
    context 'when multiple paths are provided' do
      let(:options) { { ref: 'master', path: ['PROCESS.md', 'README.md'] } }

      def commit_files(commit)
        commit.diff(commit.parent_ids.first).deltas.flat_map do |delta|
          [delta.old_file[:path], delta.new_file[:path]].uniq.compact
        end
      end

      it 'only returns commits matching at least one path' do
        commits = repository.log(options)

        expect(commits.size).to be > 0
        expect(commits).to satisfy do |commits|
          commits.none? { |commit| (commit_files(commit) & options[:path]).empty? }
        end
      end
  describe '#count_commits' do
    context 'with after timestamp' do
      it 'returns the number of commits after timestamp' do
        options = { ref: 'master', limit: nil, after: Time.iso8601('2013-03-03T20:15:01+00:00') }

        expect(repository.count_commits(options)).to eq(25)
      end
    end

    context 'with before timestamp' do
      it 'returns the number of commits after timestamp' do
        options = { ref: 'feature', limit: nil, before: Time.iso8601('2015-03-03T20:15:01+00:00') }

        expect(repository.count_commits(options)).to eq(9)
      end
    end

    context 'with path' do
      it 'returns the number of commits with path ' do
        options = { ref: 'master', limit: nil, path: "encoding" }

        expect(repository.count_commits(options)).to eq(2)
      end
    end
  end

      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      File.open(File.join(SEED_STORAGE_PATH, TEST_MUTABLE_REPO_PATH, '.git', 'config')) do |config_file|
  describe '#ref_name_for_sha' do
    let(:ref_path) { 'refs/heads' }
    let(:sha) { repository.find_branch('master').dereferenced_target.id }
    let(:ref_name) { 'refs/heads/master' }

    it 'returns the ref name for the given sha' do
      expect(repository.ref_name_for_sha(ref_path, sha)).to eq(ref_name)
    end

    it "returns an empty name if the ref doesn't exist" do
      expect(repository.ref_name_for_sha(ref_path, "000000")).to eq("")
    end

    it "raise an exception if the ref is empty" do
      expect { repository.ref_name_for_sha(ref_path, "") }.to raise_error(ArgumentError)
    end

    it "raise an exception if the ref is nil" do
      expect { repository.ref_name_for_sha(ref_path, nil) }.to raise_error(ArgumentError)
    end
  end

      branches = double()
      allow(branches).to receive(:each) { [ref].each }
      allow(repository.rugged).to receive(:branches) { branches }
      expect(repository.branch_count).to eq(9)
    let(:attributes_path) { File.join(SEED_STORAGE_PATH, TEST_REPO_PATH, 'info/attributes') }
      @repo = Gitlab::Git::Repository.new('default', File.join(TEST_MUTABLE_REPO_PATH, '.git'))

    it 'returns a Branch with UTF-8 fields' do
      branches = @repo.local_branches.to_a
      expect(branches.size).to be > 0
      branches.each do |branch|
        expect(branch.name).to be_utf8
        expect(branch.target).to be_utf8 unless branch.target.nil?
      end
    end

    it 'gets the branches from GitalyClient' do
      expect_any_instance_of(Gitlab::GitalyClient::Ref).to receive(:local_branches)
        .and_return([])
      @repo.local_branches
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::Ref, :local_branches do
      subject { @repo.local_branches }
    end