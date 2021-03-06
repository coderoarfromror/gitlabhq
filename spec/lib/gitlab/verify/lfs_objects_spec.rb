require 'spec_helper'

describe Gitlab::Verify::LfsObjects do
  include GitlabVerifyHelpers

  it_behaves_like 'Gitlab::Verify::BatchVerifier subclass' do
    let!(:objects) { create_list(:lfs_object, 3, :with_file) }
  end

  describe '#run_batches' do
    let(:failures) { collect_failures }
    let(:failure) { failures[lfs_object] }

    let!(:lfs_object) { create(:lfs_object, :with_file, :correct_oid) }

    it 'passes LFS objects with the correct file' do
      expect(failures).to eq({})
    end

    it 'fails LFS objects with a missing file' do
      FileUtils.rm_f(lfs_object.file.path)

      expect(failures.keys).to contain_exactly(lfs_object)
      expect(failure).to be_a(Errno::ENOENT)
      expect(failure.to_s).to include(lfs_object.file.path)
    end

    it 'fails LFS objects with a mismatched oid' do
      File.truncate(lfs_object.file.path, 0)

      expect(failures.keys).to contain_exactly(lfs_object)
      expect(failure.to_s).to include('Checksum mismatch')
    end

    context 'with remote files' do
      before do
        stub_lfs_object_storage
      end

      it 'skips LFS objects in object storage' do
        local_failure = create(:lfs_object)
        create(:lfs_object, :object_storage)

        failures = {}
        described_class.new(batch_size: 10).run_batches { |_, failed| failures.merge!(failed) }

        expect(failures.keys).to contain_exactly(local_failure)
      end
    end
  end
end
