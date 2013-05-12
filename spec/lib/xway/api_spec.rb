require 'spec_helper'
require 'xway/api'

describe Xway::Api do
  subject('api') { described_class.new }
  context 'mock http + endpoints' do
    let!('http') do
      double('Http').tap do |mock|
        mock.stub('request') do |server, request, debug|
          Struct\
            .new(:server, :http_options, :debug)\
            .new(server, request.http_options, debug)
        end
        Xway::Api::Http.stub('new').and_return(mock)
      end
    end
    let!('endpoints') do
      double('Endpoints').tap do |mock|
        mock.stub('foo') do |options|
          Xway::Api::Request.new 'get', '/foo', options
        end
        Xway::Api::Endpoints.stub('new').and_return(mock)
      end
    end
    let!('parameter') do
      parameter = double('Xway::Parameter').tap do |p|
        p.stub('[]').with(:servers).and_return(['http://foo',
                                                      'http://bar'])
        p.stub('[]').with(:debug).and_return(false)
        p.stub('[]').with(:app).and_return(nil)
      end
      Xway.stub('parameter').and_return(parameter)
    end

    context 'apps' do
      describe 'builds request for each server' do
        subject { api.request 'foo' }

        its('first.server')       { should eq('http://foo') }
        its('first.http_options') { should eq(:headers => {
                                                "X-App" => "appway"}) }
        its('first.debug')        { should be_false }
        its('last.server')        { should eq('http://bar') }
        its('last.http_options')  { should eq(:headers => {
                                                "X-App" => "appway"}) }
        its('last.debug')         { should be_false }
      end
    end

    context 'app name + manifest' do
      before do
        manifest = File.join(ASSETS_PATH, 'appway-example.json')
        File.stub('exists?').with(manifest).and_return(true)
        File.stub('read').with(manifest).and_return('appway-example.json.data')
        Xway.parameter.stub('[]').with(:app).and_return(name: 'appway-example',
                                                        manifest: manifest)
      end

      describe 'builds request for each server' do
        subject { api.request 'foo' }

        its('first.server')       { should eq('http://foo') }
        its('first.http_options') { should eq(:headers => {
                                                "X-App" => "appway",
                                                "Content-Type" => "application/json"},
                                              :body => "appway-example.json.data") }
        its('first.debug')        { should be_false }
        its('last.server')        { should eq('http://bar') }
        its('last.http_options')  { should eq(:headers => {
                                                "X-App" => "appway",
                                                "Content-Type" => "application/json"},
                                              :body => "appway-example.json.data") }
        its('last.debug')         { should be_false }
      end
    end
  end
end
