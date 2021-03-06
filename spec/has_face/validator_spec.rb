require 'spec_helper'

describe HasFace::Validator do

  let(:user)   { User.new(:avatar => avatar) }
  let(:avatar) { Avatar.new }

  context 'when validation is globally turned on' do

    context 'when the image is a valid face' do

      before :each do
        avatar.path = VALID_IMAGE_PATH
      end

      it 'should be valid' do
        VCR.use_cassette('valid image') do
          user.should be_valid
        end
      end

    end

    context 'when the image is not a valid face' do

      before :each do
        avatar.path = INVALID_IMAGE_PATH
      end

      it 'should not be valid' do
        VCR.use_cassette('invalid image') do
          user.should_not be_valid
        end
      end

      it 'should have an error on the image field' do
        VCR.use_cassette('invalid image') do
          user.valid?
          user.errors[:avatar].should == [ "We couldn't see a face in your photo, try taking another one." ]
        end
      end

    end

  end

  context 'when face validation is globally turned off' do

    before :each do
      stub(HasFace).enable_validation { false }
      avatar.path = INVALID_IMAGE_PATH
    end

    it 'should be valid' do
      user.should be_valid
    end

  end

  context 'handling a failure response from the face.com API' do

    let(:logger) { Logger.new(nil) }

    before :each do
      stub(HasFace).api_key { 'invalid api key' }
      stub(Rails).logger    { logger }
      avatar.path = INVALID_IMAGE_PATH
    end

    context 'when skipping validation on errors is enabled' do

      before :each do
        stub(HasFace).skip_validation_on_error { true }
        avatar.path = INVALID_IMAGE_PATH
      end

      it 'should skip validation' do
        VCR.use_cassette('invalid api key') do
          user.should be_valid
        end
      end

      it 'should log a warning' do
        VCR.use_cassette('invalid api key') do
          mock(logger).warn 'face.com API Error: "API_KEY_DOES_NOT_EXIST - invalid api key" Code: 201'
          user.valid?
        end
      end

    end

    context 'when skipping validation on errors is disabled' do

      it 'should raise an api error' do
        VCR.use_cassette('invalid api key') do
          expect { user.valid? }.to raise_error HasFace::FaceAPIError, 'face.com API Error: "API_KEY_DOES_NOT_EXIST - invalid api key" Code: 201'
        end
      end

    end

  end

  context 'handling http request errors' do

    let(:logger) { Logger.new(nil) }

    before :each do
      stub(HasFace).detect_url { 'http://face.com/invalid/lookup/url' }
      stub(Rails).logger       { logger }
      avatar.path = INVALID_IMAGE_PATH
    end

    context 'when skipping validation on errors is enabled' do

      before :each do
        stub(HasFace).skip_validation_on_error { true }
      end

      it 'should skip validation' do
        VCR.use_cassette('invalid detect url') do
          user.should be_valid
        end
      end

      it 'should log a warning' do
        VCR.use_cassette('invalid detect url') do
          mock(logger).warn 'has_face HTTP Request Error: "404 Resource Not Found"'
          user.valid?
        end
      end

    end

    context 'when skipping validation on errors is disabled' do

      it 'should raise an api error' do
        VCR.use_cassette('invalid detect url') do
          expect { user.valid? }.to raise_error HasFace::HTTPRequestError, 'has_face HTTP Request Error: "404 Resource Not Found"'
        end
      end

    end

  end

  context 'allowing blank' do

    context 'when allow blank is true' do

      let(:user) { UserWithAllowBlank.new }

      before :each do
        stub(user).avatar { "" }
      end

      it 'should be valid with a blank avatar' do
        user.should be_valid
      end

    end

    context 'when allow blank is not true' do

      let(:user) { UserWithoutAllowBlank.new }

      before :each do
        stub(user).avatar { "" }
      end

      it 'should not be valid' do
        user.should_not be_valid
      end

    end

  end

  context 'allowing nil' do

    context 'when allow nil is true' do

      let(:user) { UserWithAllowNil.new }

      before :each do
        stub(user).avatar { nil }
      end

      it 'should be valid with a nil avatar' do
        user.should be_valid
      end

    end

    context 'when allow nil is not true' do

      let(:user) { UserWithoutAllowNil.new }

      before :each do
        stub(user).avatar { nil }
      end

      it 'should not be valid' do
        user.should_not be_valid
      end

    end

  end

end
