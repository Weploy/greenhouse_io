require 'spec_helper'

describe GreenhouseIo::Client do

  FAKE_API_TOKEN = '123FakeToken'

  it "should have a base url for an API endpoint" do
    expect(GreenhouseIo::Client.base_uri).to eq("https://harvest.greenhouse.io/v1")
  end

  context "given an instance of GreenhouseIo::Client" do

    before do
      GreenhouseIo.configuration.symbolize_keys = true
      @client = GreenhouseIo::Client.new(FAKE_API_TOKEN)
    end

    describe "#initialize" do
      it "has an api_token" do
        expect(@client.api_token).to eq(FAKE_API_TOKEN)
      end

      it "uses the configuration value when token is not specified" do
        GreenhouseIo.configuration.api_token = '123FakeENV'
        default_client = GreenhouseIo::Client.new
        expect(default_client.api_token).to eq('123FakeENV')
      end
    end

    describe "#path_id" do
      context "given an id" do
        it "returns an id path" do
          output = @client.send(:path_id, 1)
          expect(output).to eq('/1')
        end
      end

      context "given no id" do
        it "returns nothing" do
          output = @client.send(:path_id)
          expect(output).to be_nil
        end
      end
    end

    describe "#set_headers_info" do
      before do
        VCR.use_cassette('client/headers') do
          @client.candidates
        end
      end

      it "sets the rate limit" do
        expect(@client.rate_limit).to eq(20)
      end

      it "sets the remaining rate limit" do
        expect(@client.rate_limit_remaining).to eq(19)
      end

      it "sets rest link" do
        expect(@client.link).to eq('<https://harvest.greenhouse.io/v1/candidates/?page=1&per_page=100>; rel="last"')
      end
    end

    describe "#permitted_options" do
      let(:options) { GreenhouseIo::Client::PERMITTED_OPTIONS + [:where] }

      it "allows permitted options" do
        output = @client.send(:permitted_options, options)
        GreenhouseIo::Client::PERMITTED_OPTIONS.each do |option|
          expect(output).to include(option)
        end
      end

      it "discards non-permitted options" do
        output = @client.send(:permitted_options, options)
        expect(output).to_not include(:where)
      end
    end

    describe "#offices" do
      context "given no id" do
        before do
          VCR.use_cassette('client/offices') do
            @offices_response = @client.offices
          end
        end

        it "returns a response" do
          expect(@offices_response).to_not be_nil
        end

        it "returns an array of offices" do
          expect(@offices_response).to be_an_instance_of(Array)
        end

        it "returns office details" do
          expect(@offices_response.first).to have_key(:name)
        end
      end

      context "given an id" do
        before do
          VCR.use_cassette('client/office') do
            @office_response = @client.offices(220)
          end
        end

        it "returns a response" do
          expect(@office_response).to_not be_nil
        end

        it "returns an office hash" do
          expect(@office_response).to be_an_instance_of(Hash)
        end

        it "returns an office's details" do
          expect(@office_response).to have_key(:name)
        end
      end
    end

    describe "#departments" do
      context "given no id" do
        before do
          VCR.use_cassette('client/departments') do
            @departments_response = @client.departments
          end
        end

        it "returns a response" do
          expect(@departments_response).to_not be_nil
        end

        it "returns an array of departments" do
          expect(@departments_response).to be_an_instance_of(Array)
        end

        it "returns office details" do
          expect(@departments_response.first).to have_key(:name)
        end
      end

      context "given an id" do
        before do
          VCR.use_cassette('client/department') do
            @department_response = @client.departments(187)
          end
        end

        it "returns a response" do
          expect(@department_response).to_not be_nil
        end

        it "returns a department hash" do
          expect(@department_response).to be_an_instance_of(Hash)
        end

        it "returns a department's details" do
          expect(@department_response).to have_key(:name)
        end
      end
    end

    describe "#candidates" do
      context "given no id" do

        before do
          VCR.use_cassette('client/candidates') do
            @candidates_response = @client.candidates
          end
        end

        it "returns a response" do
          expect(@candidates_response).to_not be_nil
        end

        it "returns an array of candidates" do
          expect(@candidates_response).to be_an_instance_of(Array)
        end

        it "returns details of candidates" do
          expect(@candidates_response.first).to have_key(:first_name)
        end
      end

      context "given an id" do
        before do
          VCR.use_cassette('client/candidate') do
            @candidate_response = @client.candidates(1)
          end
        end

        it "returns a response" do
          expect(@candidate_response).to_not be_nil
        end

        it "returns a candidate hash" do
          expect(@candidate_response).to be_an_instance_of(Hash)
        end

        it "returns a candidate's details" do
          expect(@candidate_response).to have_key(:first_name)
        end
      end
    end

    describe "#edit_candidate" do
      let(:candidate_id) { 1 }
      let(:invalid_candidate_id) { 99 }
      let(:on_behalf_of) { 2 }
      let(:invalid_on_behalf_of) { 99 }
      let(:tag) { "TAG" }
      let(:edit_hash) do
        {
          tags: [tag]
        }
      end
      it "patches a specified candidate" do
        VCR.use_cassette('client/edit_candidate') do
          edit_candidate = @client.edit_candidate(
            candidate_id,
            edit_hash,
            on_behalf_of
          )
          expect(edit_candidate).to_not be_nil
          expect(edit_candidate).to include edit_hash
        end
      end

      it "errors when given invalid On-Behalf-Of id" do
        VCR.use_cassette('client/edit_candidate_invalid_on_behalf_of') do
          expect {
            @client.edit_candidate(
              candidate_id,
              edit_hash,
              invalid_on_behalf_of
            )
          }.to raise_error(GreenhouseIo::Error)
        end
      end

      it "errors when given an invalid candidate id" do
        VCR.use_cassette('client/edit_candidate_invalid_candidate_id') do
          expect {
            @client.edit_candidate(
              invalid_candidate_id,
              edit_hash,
              on_behalf_of
            )
          }.to raise_error(GreenhouseIo::Error)
        end
      end
    end

    describe "#add_attachment_to_candidate" do
      let(:candidate_id) { 1 }
      let(:on_behalf_of) { 2 }
      let(:attachment_hash) do
        {
          filename: 'test_file.pdf',
          type: 'admin_only',
          content: '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',
          content_type: 'application/pdf',
        }
      end

      it "adds the attachment to the candidate" do
        VCR.use_cassette('client/add_attachment_to_candidate') do
          add_attachment_to_candidate = @client.add_attachment_to_candidate(
            candidate_id,
            attachment_hash,
            on_behalf_of
          )
          expect(add_attachment_to_candidate).to_not be_nil
          expect(add_attachment_to_candidate.keys).to contain_exactly(:filename, :url, :type)
          expect(add_attachment_to_candidate[:filename]).to eq(attachment_hash[:filename])
        end
      end
    end

    describe "#activity_feed" do
      before do
        VCR.use_cassette('client/activity_feed') do
          @activity_feed = @client.activity_feed(1)
        end
      end

      it "returns a response" do
        expect(@activity_feed).to_not be_nil
      end

      it "returns an activity feed" do
        expect(@activity_feed).to be_an_instance_of(Hash)
      end

      it "returns details of the activity feed" do
        expect(@activity_feed).to have_key(:activities)
      end
    end

    describe "#create_candidate_note" do
      it "posts an note for a specified candidate" do
        VCR.use_cassette('client/create_candidate_note') do
          create_candidate_note = @client.create_candidate_note(
            1,
            {
                user_id: 2,
                message: "Candidate on vacation",
                visibility: "public"
            },
            2
          )
          expect(create_candidate_note).to_not be_nil
          expect(create_candidate_note).to include :body => 'Candidate on vacation'
        end
      end

      it "errors when given invalid On-Behalf-Of id" do
        VCR.use_cassette('client/create_candidate_note_invalid_on_behalf_of') do
          expect {
            @client.create_candidate_note(
              1,
              {
                  user_id: 2,
                  message: "Candidate on vacation",
                  visibility: "public"
              },
              99
            )
          }.to raise_error(GreenhouseIo::Error)
        end
      end

      it "errors when given an invalid candidate id" do
        VCR.use_cassette('client/create_candidate_note_invalid_candidate_id') do
          expect {
            @client.create_candidate_note(
              99,
              {
                  user_id: 2,
                  message: "Candidate on vacation",
                  visibility: "public"
              },
              2
            )
          }.to raise_error(GreenhouseIo::Error)
        end
      end

      it "errors when given an invalid user_id" do
        VCR.use_cassette('client/create_candidate_note_invalid_user_id') do
          expect {
            @client.create_candidate_note(
              1,
              {
                  user_id: 99,
                  message: "Candidate on vacation",
                  visibility: "public"
              },
              2
            )
          }.to raise_error(GreenhouseIo::Error)
        end
      end

      it "errors when missing required field" do
        VCR.use_cassette('client/create_candidate_note_invalid_missing_field') do
          expect {
            @client.create_candidate_note(
              1,
              {
                  user_id: 2,
                  visibility: "public"
              },
              2
            )
          }.to raise_error(GreenhouseIo::Error)
        end
      end
    end

    describe "#applications" do
      context "given no id" do
        before do
          VCR.use_cassette('client/applications') do
            @applications = @client.applications
          end
        end

        it "returns a response" do
          expect(@applications).to_not be_nil
        end

        it "returns an array of applications" do
          expect(@applications).to be_an_instance_of(Array)
        end

        it "returns application details" do
          expect(@applications.first).to have_key(:person_id)
        end
      end

      context "given an id" do
        before do
          VCR.use_cassette('client/application') do
            @application = @client.applications(1)
          end
        end

        it "returns a response" do
          expect(@application).to_not be_nil
        end

        it "returns an application hash" do
          expect(@application).to be_an_instance_of(Hash)
        end

        it "returns an application's details" do
          expect(@application).to have_key(:person_id)
        end
      end

      context "given a job_id" do
        before do
          VCR.use_cassette('client/application_by_job_id') do
            @applications = @client.applications(nil, :job_id => 144371)
          end
        end

        it "returns a response" do
          expect(@applications).to_not be_nil
        end

        it "returns an array of applications" do
          expect(@applications).to be_an_instance_of(Array)
          expect(@applications.first).to be_an_instance_of(Hash)
          expect(@applications.first).to have_key(:prospect)
        end
      end
    end

    describe "#scorecards" do
      before do
        VCR.use_cassette('client/scorecards') do
          @scorecard = @client.scorecards(1)
        end
      end

      it "returns a response" do
        expect(@scorecard).to_not be_nil
      end

      it "returns an array of scorecards" do
        expect(@scorecard).to be_an_instance_of(Array)
      end

      it "returns details of the scorecards" do
        expect(@scorecard.first).to have_key(:interview)
      end
    end

    describe "#all_scorecards" do
      before do
        VCR.use_cassette('client/all_scorecards') do
          @scorecard = @client.all_scorecards
        end
      end

      it "returns a response" do
        expect(@scorecard).to_not be_nil
      end

      it "returns an array of scorecards" do
        expect(@scorecard).to be_an_instance_of(Array)
      end

      it "returns details of the scorecards" do
        expect(@scorecard.first).to have_key(:interview)
      end
    end

    describe "#scheduled_interviews" do
      before do
        VCR.use_cassette('client/scheduled_interviews') do
          @scheduled_interviews = @client.scheduled_interviews(1)
        end
      end

      it "returns a response" do
        expect(@scheduled_interviews).to_not be_nil
      end

      it "returns an array of scheduled interviews" do
        expect(@scheduled_interviews).to be_an_instance_of(Array)
      end

      it "returns details of the interview" do
        expect(@scheduled_interviews.first).to have_key(:starts_at)
      end
    end

    describe "#jobs" do
      context "given no id" do
        before do
          VCR.use_cassette('client/jobs') do
            @jobs = @client.jobs
          end
        end

        it "returns a response" do
          expect(@jobs).to_not be_nil
        end

        it "returns an array of applications" do
          expect(@jobs).to be_an_instance_of(Array)
        end

        it "returns application details" do
          expect(@jobs.first).to have_key(:employment_type)
        end
      end

      context "given an id" do
        before do
          VCR.use_cassette('client/job') do
            @job = @client.jobs(4690)
          end
        end

        it "returns a response" do
          expect(@job).to_not be_nil
        end

        it "returns an application hash" do
          expect(@job).to be_an_instance_of(Hash)
        end

        it "returns an application's details" do
          expect(@job).to have_key(:employment_type)
        end
      end
    end

    describe "#stages" do
      before do
        VCR.use_cassette('client/stages') do
          @stages = @client.stages(4690)
        end
      end

      it "returns a response" do
        expect(@stages).to_not be_nil
      end

      it "returns an array of scheduled interviews" do
        expect(@stages).to be_an_instance_of(Array)
      end

      it "returns details of the interview" do
        expect(@stages.first).to have_key(:name)
      end
    end

    describe "#job_post" do
      before do
        VCR.use_cassette('client/job_post') do
          @job_post = @client.job_post(4690)
        end
      end

      it "returns a response" do
        expect(@job_post).to_not be_nil
      end

      it "returns an array of scheduled interviews" do
        expect(@job_post).to be_an_instance_of(Hash)
      end

      it "returns details of the interview" do
        expect(@job_post).to have_key(:title)
      end
    end

    describe "#users" do
      context "given no id" do
        before do
          VCR.use_cassette('client/users') do
            @users = @client.users
          end
        end

        it "returns a response" do
          expect(@users).to_not be_nil
        end

        it "returns an array of applications" do
          expect(@users).to be_an_instance_of(Array)
        end

        it "returns application details" do
          expect(@users.first).to have_key(:name)
        end
      end

      context "given an id" do
        before do
          VCR.use_cassette('client/user') do
            @job = @client.users(10327)
          end
        end

        it "returns a response" do
          expect(@job).to_not be_nil
        end

        it "returns an application hash" do
          expect(@job).to be_an_instance_of(Hash)
        end

        it "returns an application's details" do
          expect(@job).to have_key(:name)
        end
      end
    end

    describe "#sources" do
      context "given no id" do
        before do
          VCR.use_cassette('client/sources') do
            @sources = @client.sources
          end
        end

        it "returns a response" do
          expect(@sources).to_not be_nil
        end

        it "returns an array of applications" do
          expect(@sources).to be_an_instance_of(Array)
        end

        it "returns application details" do
          expect(@sources.first).to have_key(:name)
        end
      end

      context "given an id" do
        before do
          VCR.use_cassette('client/source') do
            @source = @client.sources(1)
          end
        end

        it "returns a response" do
          expect(@source).to_not be_nil
        end

        it "returns an application hash" do
          expect(@source).to be_an_instance_of(Hash)
        end

        it "returns an application's details" do
          expect(@source).to have_key(:name)
        end
      end
    end

    describe "#offers" do
      context "given no id" do
        before do
          VCR.use_cassette('client/offers') do
            @offers = @client.offers
          end
        end

        it "returns a response" do
          expect(@offers).to_not be nil
        end

        it "returns an array of offers" do
          expect(@offers).to be_an_instance_of(Array)
          expect(@offers.first[:id]).to be_a(Integer).and be > 0
          expect(@offers.first[:created_at]).to be_a(String)
          expect(@offers.first[:version]).to be_a(Integer).and be > 0
          expect(@offers.first[:status]).to be_a(String)
        end
      end

      context "given an id" do
        before do
          VCR.use_cassette('client/offer') do
            @offer = @client.offers(221598)
          end
        end

        it "returns a response" do
          expect(@offer).to_not be nil
        end

        it "returns an offer object" do
          expect(@offer).to be_an_instance_of(Hash)
          expect(@offer[:id]).to be_a(Integer).and be > 0
          expect(@offer[:created_at]).to be_a(String)
          expect(@offer[:version]).to be_a(Integer).and be > 0
          expect(@offer[:status]).to be_a(String)
        end
      end
    end

    describe "#offers_for_application" do
      before do
        VCR.use_cassette('client/offers_for_application') do
          @offers = @client.offers_for_application(123)
        end
      end

      it "returns a response" do
        expect(@offers).to_not be_nil
      end

      it "returns an array of offers" do
        expect(@offers).to be_an_instance_of(Array)

        return unless @offers.size > 0
        expect(@offers.first).to have_key(:application_id)
        expect(@offers.first).to have_key(:version)
        expect(@offers.first).to have_key(:status)
      end
    end

    describe "#current_offer_for_application" do
      before do
        VCR.use_cassette('client/current_offer_for_application') do
          @offer = @client.current_offer_for_application(123)
        end
      end

      it "returns a response" do
        expect(@offer).to_not be_nil
      end

      it "returns an offer object" do
        expect(@offer).to be_an_instance_of(Hash)
        expect(@offer[:id]).to be_a(Integer).and be > 0
        expect(@offer[:created_at]).to be_a(String)
        expect(@offer[:version]).to be_a(Integer).and be > 0
        expect(@offer[:status]).to be_a(String)
      end
    end
  end
end
