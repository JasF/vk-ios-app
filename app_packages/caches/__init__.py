from .messages import MessagesDatabase
from .users import UsersDatabase

MessagesDatabase.deleteDatabaseFile(MessagesDatabase)
UsersDatabase.deleteDatabaseFile(UsersDatabase)
