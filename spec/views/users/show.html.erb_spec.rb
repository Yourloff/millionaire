require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context 'view by current user' do
    before do
      current_user = assign(:user, build_stubbed(:user, name: 'Alexey'))
      allow(view).to receive(:current_user).and_return(current_user)

      render
    end

    it 'render user name' do
      expect(rendered).to match 'Alexey'
    end

    it 'renders change password button' do
      expect(rendered).to match 'Сменить имя и пароль'
    end

    it 'renders game partial' do
      assign(:games, [build_stubbed(:game)])
      stub_template 'users/_game.html.erb' => "User game goes here"

      render
      expect(rendered).to match "User game goes here"
    end
  end

  context 'view by non-current user' do
    before do
      assign(:user, build_stubbed(:user, name: 'Alexey'))

      render
    end

    it 'render user name' do
      expect(rendered).to match 'Alexey'
    end

    it 'does not render button for change password' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end
end
