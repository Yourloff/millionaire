require 'rails_helper'

RSpec.feature 'View another player profile', type: :feature do

  let(:user) { create :user, name: 'Alexey' }

  let(:first_game) do
    FactoryBot.create(
      :game,
      user: user,
      current_level: 7,
      created_at: Time.parse('21.07.2022, 22:00'),
      finished_at: Time.parse('21.07.2022, 22:10'),
      prize: 32000
    )
  end

  let(:second_game) do
    FactoryBot.create(
      :game,
      user: user,
      current_level: 5,
      created_at: Time.parse('21.07.2022, 21:45'),
      finished_at: Time.parse('21.07.2022, 22:00'),
      fifty_fifty_used: true,
      prize: 1000
    )
  end

  let!(:games) { [first_game, second_game] }

  feature 'anonim views another player profile' do
    before { visit '/users/1' }

    it 'correct user address' do
      expect(page).to have_current_path "/users/#{user.id}"
    end

    it 'should have page owner name' do
      expect(page).to have_content 'Alexey'
    end

    it 'should not have profile edit button' do
      expect(page).not_to have_content 'Сменить имя и пароль'
    end

    context 'correct render games' do
      it 'games count player' do
        expect(page).to have_selector 'tr.text-center', count: games.count
      end

      it 'prizes' do
        expect(page).to have_content 'деньги'
        expect(page).to have_content '32 000 ₽'
        expect(page).to have_content '1 000 ₽'
      end

      it 'dates is displayed correctly' do
        expect(page).to have_content '21 июля, 22:00'
        expect(page).to have_content '21 июля, 21:45'
      end

      it 'used helpers' do
        expect(page).to have_content '50/50'
      end
    end
  end
end
