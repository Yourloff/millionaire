require 'rails_helper'

RSpec.describe GameQuestion, type: :model do
  let(:game_question) { create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  describe '#variants' do
    it 'should return correct .variants' do
      expect(game_question.variants).to eq(
                                          'a' => game_question.question.answer2,
                                          'b' => game_question.question.answer1,
                                          'c' => game_question.question.answer4,
                                          'd' => game_question.question.answer3
                                        )
    end
  end

  describe '#answer_correct?' do
    it 'correct .answer_correct?' do
      expect(game_question.answer_correct?('b')).to be true
    end
  end

  describe '#text' do
    it 'should return question text' do
      expect(game_question.text).to eq(game_question.question.text)
    end
  end

  describe '#level' do
    it 'should return question level' do
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  describe '#correct_answer_key' do
    context 'when .correct_answer is b' do
      it 'should return b' do
        expect(game_question.correct_answer_key).to eq 'b'
      end
    end
  end

  describe '#friend_call' do
    context 'and friend call has not been used before' do
      before { game_question.add_friend_call }

      it 'add friend call to help_hash' do
        expect(game_question.help_hash).to include(:friend_call)
      end

      it 'contain correct answer' do
        expect(game_question.help_hash[:friend_call]).to include('считает, что это вариант')
        expect(game_question.help_hash[:friend_call].last.downcase).to be_in(%w(a b c d))
      end
    end
  end

  describe '#fifty_fifty' do
    context 'when fifty-fifty has not been used before' do
      before do
        expect(game_question.help_hash).not_to include(:fifty_fifty)

        game_question.add_fifty_fifty
      end

      it 'fifty-fifty help to .help_hash' do
        expect(game_question.help_hash).to include(:fifty_fifty)
      end

      it 'fifty-fifty help has 2 keys' do
        expect(game_question.help_hash[:fifty_fifty].size).to eq 2
      end

      it 'fifty-fifty help with correct answer key' do
        expect(game_question.help_hash[:fifty_fifty]).to include(game_question.correct_answer_key)
      end
    end
  end
end
