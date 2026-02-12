import logging
from aiogram import Bot, Dispatcher, types
from aiogram.contrib.fsm_storage.memory import MemoryStorage
from aiogram.utils import executor
from sqlalchemy import create_engine, Column, Integer, String, select
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Setup logging
logging.basicConfig(level=logging.INFO)

# Bot configuration
API_TOKEN = '7391513751:AAH19Y464rzZt-2NXSCCD6KDCHMzFWashDw'

# Initialize bot and dispatcher
bot = Bot(token=API_TOKEN)
dispatcher = Dispatcher(bot, storage=MemoryStorage())

# Database setup
Base = declarative_base()

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    username = Column(String, unique=True)
    score = Column(Integer, default=0)

DATABASE_URL = 'sqlite:///winners.db'
engine = create_engine(DATABASE_URL)
Base.metadata.create_all(engine)
Session = sessionmaker(bind=engine)

# Command to start the bot
@dispatcher.message_handler(commands=['start'])
async def start_command(message: types.Message):
    await message.reply("Welcome to the English Learning Bot! Use /leaderboard to see top users.")

# Command to show leaderboard
@dispatcher.message_handler(commands=['leaderboard'])
async def leaderboard_command(message: types.Message):
    session = Session()
    top_users = session.query(User).order_by(User.score.desc()).limit(20).all()
    leaderboard = "Top 20 Winners:\n"
    for user in top_users:
        leaderboard += f"{user.username}: {user.score}\n"
    await message.reply(leaderboard)
    session.close()

# Placeholder for handling answers and updating scores
# Add your quiz handling logic here.

if __name__ == '__main__':
    executor.start_polling(dispatcher, skip_updates=True)
