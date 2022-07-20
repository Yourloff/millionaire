require 'rails_helper'
require 'support/my_spec_helper'

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  describe '#take_money' do
    context 'user is not authorized' do
      before { put :take_money, id: game_w_questions.id }

      it 'should not have response status 302' do
        expect(response.status).to eq(302)
      end

      it 'should redirect to sign_up path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should place flash alert message' do
        expect(flash[:alert]).to be
      end
    end

    context 'user is logged in' do
      before { sign_in user }

      it 'should stops the game & update user balance' do
        game_w_questions.update_attribute(:current_level, 2)

        put :take_money, id: game_w_questions.id
        game = assigns(:game)
        expect(game.finished?).to be true
        expect(game.prize).to eq(200)

        user.reload
        expect(user.balance).to eq(200)

        expect(response).to redirect_to(user_path(user))
        expect(flash[:warning]).to be
      end
    end
  end

  describe '#create' do
    context 'when anon' do
      before { post :create }

      it 'should have response status not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'should redirect to sign_up path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should place flash alert message' do
        expect(flash[:alert]).to be
      end
    end

    context 'user is logged in' do
      before(:each) do
        sign_in user
        generate_questions(15)
        post :create
      end

      let(:game) { assigns(:game) }

      context 'game state not finished' do
        before do
          expect(game.finished?).to be false
        end

        it 'redirect to game in progress' do
          expect(response).to redirect_to(game_path(game))
        end
      end
    end
  end

  describe '#show' do
    context 'user is not authorized' do
      before { get :show, id: game_w_questions.id }

      it 'should not have response status 200' do
        expect(response.status).not_to eq(200)
      end

      it 'should redirect to sign_up path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should place flash alert message' do
        expect(flash[:alert]).to be
      end
    end

    context 'user is logged in' do
      let!(:signed_in) { sign_in user }

      context 'and should have access to his game' do
        before { get :show, id: game_w_questions.id }

        it 'should provide unfinished game' do
          game = assigns(:game)
          expect(game.finished?).to be false
        end

        it 'should match user to game.user' do
          game = assigns(:game)
          expect(game.user).to eq(user)
        end

        it 'should have response status 200' do
          expect(response.status).to eq(200)
        end

        it 'should render template show' do
          expect(response).to render_template('show')
        end
      end

      context 'and should not have access to alien game' do
        it 'show alien game' do
          alien_game = FactoryBot.create(:game_with_questions)

          get :show, id: alien_game.id

          expect(response.status).not_to eq(200)
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#answer' do
    context 'user is not authorized' do
      before { put :create, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }

      it 'should have response status 302' do
        expect(response.status).to eq(302)
      end

      it 'should redirect to sign_up path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should place flash alert message' do
        expect(flash[:alert]).to be
      end
    end

    context 'user is logged in' do
      before { sign_in user }

      context 'and should accept correct answer' do
        before { put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }
        let(:seted_game) { assigns(:game) }

        it 'should not change game state to finished' do
          expect(seted_game.finished?).to be false
        end

        it 'should increment game current level' do
          expect(seted_game.current_level).to be > 0
        end

        it 'sholud redirect to game_path' do
          expect(response).to redirect_to(game_path(seted_game))
        end

        it 'should not place any flashes' do
          expect(flash.empty?).to be true
        end
      end

      context 'and should react to incorrect answer' do
        before do
          incorrect_answer =
            %w[a b c d].grep_v(game_w_questions.current_game_question.correct_answer_key).sample

          put :answer, id: game_w_questions.id, letter: incorrect_answer
        end
        let(:seted_game) { assigns(:game) }

        it 'should change game state to finished' do
          expect(seted_game.finished?).to be true
        end

        it 'should not change game current level' do
          expect(seted_game.current_level).to be 0
        end

        it 'should change game staus to :fail' do
          expect(seted_game.status).to eq :fail
        end

        it 'sholud redirect to user_path' do
          expect(response).to redirect_to user_path(user)
        end

        it 'should place flashes alert message' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#help' do
    it 'should not be audience_help for new question' do
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be false
    end

    it 'should not be fifty_fifty for new question' do
      expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
      expect(game_w_questions.fifty_fifty_used).to be false
    end

    context 'user logged in' do
      before { sign_in user }
      let(:seted_game) { assigns(:game) }

      context 'and audience_help' do
        before { put :help, id: game_w_questions.id, help_type: :audience_help }

        it 'should not finish the game' do
          expect(seted_game.finished?).to be false
        end

        it 'should place audience_help flag to true' do
          expect(seted_game.audience_help_used).to be true
        end

        it 'should place audience_help content in help hash' do
          expect(seted_game.current_game_question.help_hash[:audience_help]).to be
        end

        it 'sholud place a, b, c, d in audience_help key' do
          expect(seted_game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
        end

        it 'should redirect to game_path' do
          expect(response).to redirect_to(game_path(seted_game))
        end
      end

      context 'fifty_fifty' do
        before { put :help, id: game_w_questions.id, help_type: :fifty_fifty }

        it 'should not finish the game' do
          expect(seted_game.finished?).to be false
        end

        it 'should place fifty_fifty flag to true' do
          expect(seted_game.fifty_fifty_used).to be true
        end

        it 'should place fifty_fifty content in help hash' do
          expect(seted_game.current_game_question.help_hash[:fifty_fifty]).to be
        end

        it 'should contain 2 elements exactly' do
          expect(seted_game.current_game_question.help_hash[:fifty_fifty].size).to eq 2
        end

        it 'should contain correct answer' do
          correct_answer = seted_game.current_game_question.correct_answer_key

          expect(seted_game.current_game_question.help_hash[:fifty_fifty]).to include(correct_answer)
        end

        it 'should redirect to game_path' do
          expect(response).to redirect_to(game_path(seted_game))
        end
      end
    end
  end
end
