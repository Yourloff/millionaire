require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { FactoryGirl.create(:user) }

  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      generate_questions(60)

      game = nil
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15).and(
          change(Question, :count).by(0)
        )
      )
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  context 'game mechanics' do
    it 'answer correct continues game' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)

      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'take_money! finishes the game' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      game_w_questions.take_money!

      prize = game_w_questions.prize
      expect(prize).to be > 0

      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end
  end

  describe '#previous_level' do
    context 'current level = 0' do
      it 'should return -1 if the game is new' do
        game_w_questions.current_level = 0
        expect(game_w_questions.previous_level).to eq(-1)
      end
    end
  end

  describe '#current_game_question' do
    it 'return current game question' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions.first)
    end
  end

  describe '#answer_current_question!' do
    context 'when answer is wrong' do
      let(:wrong_answer_key) do
        %w[a b c d].grep_v(game_w_questions.current_game_question.correct_answer_key).sample
      end

      before { game_w_questions.answer_current_question!(wrong_answer_key) }

      it 'should finish game' do
        game_w_questions.answer_current_question!(wrong_answer_key)
        expect(game_w_questions.finished?).to be true
      end

      it 'should assign status fail' do
        game_w_questions.answer_current_question!(wrong_answer_key)
        expect(game_w_questions.status).to eq(:fail)
      end
    end

    context 'when answer is correct' do
      let(:correct_answer_key) do
        game_w_questions.current_game_question.correct_answer_key
      end

      context 'and question is last' do
        before { game_w_questions.current_level = 14 }
        let!(:answer_last_question) { game_w_questions.answer_current_question!(correct_answer_key) }

        it 'should assign final prize' do
          expect(game_w_questions.prize).to eq Game::PRIZES.last
        end

        it 'should finish game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'should assign status won' do
          expect(game_w_questions.status).to eq(:won)
        end
      end

      context 'and question is not last' do
        let!(:level) { game_w_questions.current_level = 2 }
        let!(:answer_question) { game_w_questions.answer_current_question!(correct_answer_key) }

        it 'should increase the current level by 1' do
          expect(game_w_questions.current_level).to eq(3)
        end

        it 'should not finish game' do
          expect(game_w_questions.finished?).to be false
        end

        it 'should stay in progress status' do
          expect(game_w_questions.status).to eq(:in_progress)
        end
      end

      context 'and time is over ' do
        let!(:time_is_up) do
          game_w_questions.created_at = 1.hour.ago
          game_w_questions.answer_current_question!(correct_answer_key)
        end

        it 'should finish game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'should assign status timeout' do
          expect(game_w_questions.status).to eq(:timeout)
        end
      end
    end
  end

  context '.status' do
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end
end
