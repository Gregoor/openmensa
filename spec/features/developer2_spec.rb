# encoding: UTF-8
require File.dirname(__FILE__) + '/../spec_helper'
require_dependency 'message'

describe 'Developers', type: :feature do
  let(:user) { FactoryGirl.create :user }
  let(:developer) { FactoryGirl.create :developer }
  let(:parser) { FactoryGirl.create :parser, user_id: developer.id }
  let(:canteen) { FactoryGirl.create :canteen, user_id: developer.id }

  context 'as a developer' do
    before do
      parser
      login_as developer
      click_on 'Profil'
    end

    context 'without existing parser' do
      let(:parser) {}

      it 'should be able to add a new parser' do
        click_on 'Neuen Parser anlegen'
        expect(page).to have_link_to 'http://doc.openmensa.org/parsers/'
        expect(page).to have_link_to 'http://doc.openmensa.org/feed/v2/'

        fill_in 'Name', with: 'Magdeburg'
        click_on 'Speichern'

        expect(page).to have_content 'Der Parser wurde erfolgreich angelegt.'
      end
    end

    context 'with existing parser' do
      it 'should be able to edit a new parser' do
        click_on parser.name

        fill_in 'Name', with: 'Magdeburg'
        click_on 'Speichern'

        expect(page).to have_content 'Der Parser wurde erfolgreich aktualisiert.'
      end

      it 'should be able to import sources from info url' do
        info_url = 'http://example.org/sources.json'
        stub_request(:any, info_url)
          .to_return(body: mock_file('sources.json'), status: 200)

        click_on parser.name
        expect(page).to_not have_link('Aktualisiere Quellen mittels Info-URL')

        fill_in 'Info-URL', with: info_url
        click_on 'Speichern'

        click_on 'Aktualisiere Quellen mittels Info-URL'

        expect(page).to have_content '2 Quellen hinzugefügt.'
      end

      it 'should be able to delete a parser' do
        pending 'todo'
        click_on parser.name

        click_on 'Parser archivieren'

        expect(page).to have_content 'Der Parser wurde archiviert!'
      end

      context 'with archived parser' do
        it 'should be able to reactive a parser' do
          pending 'todo'
          click_on 'Neuen Parser anlegen'

          click_on "\#{parser.name}\" reaktivieren"

          expect(page).to have_content 'Der Parser wurde reaktiviert!'
        end
      end

      context 'with a existing source without meta url' do
        let!(:source) { FactoryGirl.create :source, parser: parser }
        let!(:feed) { FactoryGirl.create :feed, source: source }

        it 'should be able to edit the source' do
          click_on parser.name
          click_on "Editiere #{source.name}"

          within(:xpath, '//section[header="Editiere Quelle"]') do
            fill_in 'Name', with: 'Testname'
            click_on 'Speichern'
          end

          expect(page).to have_content 'Testname'
          expect(page).to have_content 'Die Quelle wurde erfolgeich aktualisiert.'
        end

        it 'should be able to add a new feed' do
          click_on parser.name
          click_on "Editiere #{source.name}"

          within(:xpath, '//section[header="Neuer Feed"]') do
            fill_in 'Name', with: 'Full'
            fill_in 'URL', with: 'http://example.org/test/full.xml'
            fill_in 'Wiederholungsinterval(e)', with: '10 3'
          end

          click_on 'Feed anlegen'

          expect(page).to have_content 'Der neuer Feed wurde erfolgreich angelegt.'
          expect(page).to have_content 'Feed Full'
        end

        it 'should be able to edit a feed' do
          click_on parser.name
          click_on "Editiere #{source.name}"

          within(:xpath, '//section[header="Feed ' + feed.name + '"]') do
            fill_in 'Name', with: 'Replacefeed'
            fill_in 'Wiederholungsinterval(e)', with: ''
            click_on 'Speichern'
          end

          expect(page).to have_content 'Der Feed wurde erfolgreich aktualisiert.'
          expect(page).to have_content 'Replacefeed'
        end

        it 'should be able to delete/archive a feed' do
          click_on parser.name
          click_on "Editiere #{source.name}"

          within(:xpath, '//section[header="Feed ' + feed.name + '"]') do
            click_on 'Löschen'
          end

          expect(page).to have_content 'Der Feed wurde erfolgreich geschlöscht.'
          expect(page).to_not have_content feed.name
        end
      end
    end
  end
end