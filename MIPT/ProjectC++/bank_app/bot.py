import os
import logging
import asyncio
from aiogram import Bot, Dispatcher, types
from aiogram.filters import Command, CommandObject
from aiogram.types import ReplyKeyboardMarkup, KeyboardButton
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.utils.keyboard import InlineKeyboardBuilder
from aiogram.types import BotCommand

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

TOKEN = "7328818129:AAHPyi3c4uYnXPzrYqG6v3lMBkBgKLVtz2Y"
CPP_BINARY = "./bank_app"

bot = Bot(token=TOKEN)
dp = Dispatcher()

main_keyboard = ReplyKeyboardMarkup(
    keyboard=[
        [KeyboardButton(text="Зарегистрировать пользователя")],
        [KeyboardButton(text="Создать новый счёт")],
        [KeyboardButton(text="Перевести деньги")],
        [KeyboardButton(text="Узнать баланс")]
    ],
    resize_keyboard=True
)

class Form(StatesGroup):
    reg_name = State()
    reg_lastname = State()
    reg_address = State()
    reg_passport = State()
    account_passport = State()
    account_type = State()
    account_balance = State()
    transfer_from = State()
    transfer_to = State()
    transfer_amount = State()
    balance_name = State()
    balance_lastname = State()
    select_account = State()

@dp.message(Command("start"))
async def cmd_start(message: types.Message):
    await message.answer(
        "👋 Добро пожаловать в банковскую систему!\n"
        "Выберите действие:",
        reply_markup=main_keyboard
    )

@dp.message(lambda message: message.text == "Зарегистрировать пользователя")
async def register_user_start(message: types.Message, state: FSMContext):
    await message.answer("Введите имя:")
    await state.set_state(Form.reg_name)

@dp.message(Form.reg_name)
async def process_name(message: types.Message, state: FSMContext):
    await state.update_data(name=message.text)
    await message.answer("Введите фамилию:")
    await state.set_state(Form.reg_lastname)

@dp.message(Form.reg_lastname)
async def process_lastname(message: types.Message, state: FSMContext):
    await state.update_data(lastname=message.text)
    await message.answer("Введите адрес:")
    await state.set_state(Form.reg_address)

@dp.message(Form.reg_address)
async def process_address(message: types.Message, state: FSMContext):
    await state.update_data(address=message.text)
    await message.answer("Введите паспортные данные:")
    await state.set_state(Form.reg_passport)

@dp.message(Form.reg_passport)
async def process_passport(message: types.Message, state: FSMContext):
    user_data = await state.get_data()
    result = await run_cpp_command([
        "create_user",
        user_data['name'],
        user_data['lastname'],
        user_data['address'],
        message.text
    ])
    await message.answer(result)
    await state.clear()

@dp.message(lambda message: message.text == "Создать новый счёт")
async def create_account_start(message: types.Message, state: FSMContext):
    await message.answer("Введите паспортные данные:")
    await state.set_state(Form.account_passport)

@dp.message(Form.account_passport)
async def process_account_passport(message: types.Message, state: FSMContext):
    result = await run_cpp_command(["check_user", message.text])
    if "не найден" in result:
        await message.answer(result)
        await state.clear()
        return

    await state.update_data(passport=message.text)
    keyboard = ReplyKeyboardMarkup(
        keyboard=[
            [KeyboardButton(text="Дебетовый")],
            [KeyboardButton(text="Кредитный")],
            [KeyboardButton(text="Накопительный")]
        ],
        resize_keyboard=True
    )
    await message.answer("Выберите тип счета:", reply_markup=keyboard)
    await state.set_state(Form.account_type)

@dp.message(Form.account_type)
async def process_account_type(message: types.Message, state: FSMContext):
    type_map = {
        "Дебетовый": "0",
        "Кредитный": "1",
        "Накопительный": "2"
    }
    if message.text not in type_map:
        await message.answer("Неверный тип счета!")
        return

    await state.update_data(type=type_map[message.text])
    await message.answer("Введите начальный баланс:", reply_markup=types.ReplyKeyboardRemove())
    await state.set_state(Form.account_balance)

@dp.message(Form.account_balance)
async def process_account_balance(message: types.Message, state: FSMContext):
    try:
        balance = float(message.text)
    except ValueError:
        await message.answer("Неверный формат суммы!")
        return

    user_data = await state.get_data()
    result = await run_cpp_command([
        "create_account",
        user_data['passport'],
        user_data['type'],
        str(balance)
    ])
    await message.answer(result, reply_markup=main_keyboard)
    await state.clear()

@dp.message(lambda message: message.text == "Перевести деньги")
async def transfer_money_start(message: types.Message, state: FSMContext):
    await message.answer("Введите паспорт отправителя:")
    await state.set_state(Form.transfer_from)

@dp.message(Form.transfer_from)
async def process_transfer_from(message: types.Message, state: FSMContext):
    result = await run_cpp_command(["check_user", message.text])
    if "не найден" in result:
        await message.answer(result)
        await state.clear()
        return

    await state.update_data(from_passport=message.text)
    await message.answer("Введите паспорт получателя:")
    await state.set_state(Form.transfer_to)

@dp.message(Form.transfer_to)
async def process_transfer_to(message: types.Message, state: FSMContext):
    result = await run_cpp_command(["check_user", message.text])
    if "не найден" in result:
        await message.answer(result)
        await state.clear()
        return

    await state.update_data(to_passport=message.text)
    await message.answer("Введите сумму перевода:")
    await state.set_state(Form.transfer_amount)

@dp.message(Form.transfer_amount)
async def process_transfer_amount(message: types.Message, state: FSMContext):
    try:
        amount = float(message.text)
    except ValueError:
        await message.answer("Неверный формат суммы!")
        return

    user_data = await state.get_data()
    result = await run_cpp_command([
        "transfer",
        user_data['from_passport'],
        user_data['to_passport'],
        str(amount)
    ])
    await message.answer(result, reply_markup=main_keyboard)
    await state.clear()

@dp.message(lambda message: message.text == "Узнать баланс")
async def check_balance_start(message: types.Message, state: FSMContext):
    await message.answer("Введите имя пользователя:")
    await state.set_state(Form.balance_name)

@dp.message(Form.balance_name)
async def process_balance_name(message: types.Message, state: FSMContext):
    await state.update_data(name=message.text)
    await message.answer("Введите фамилию пользователя:")
    await state.set_state(Form.balance_lastname)

@dp.message(Form.balance_lastname)
async def process_balance_lastname(message: types.Message, state: FSMContext):
    user_data = await state.get_data()
    result = await run_cpp_command([
        "find_user",
        user_data['name'],
        message.text
    ])
    if "не найден" in result:
        await message.answer(result)
        await state.clear()
        return

    accounts = parse_accounts(result)
    if not accounts:
        await message.answer("Нет доступных счетов")
        await state.clear()
        return

    buttons = [[KeyboardButton(text=acc['id'])] for acc in accounts]
    keyboard = ReplyKeyboardMarkup(
        keyboard=buttons,
        resize_keyboard=True
    )
    await state.update_data(accounts=accounts)
    await message.answer("Выберите счет:", reply_markup=keyboard)
    await state.set_state(Form.select_account)

@dp.message(Form.select_account)
async def process_select_account(message: types.Message, state: FSMContext):
    user_data = await state.get_data()
    selected = next((acc for acc in user_data['accounts'] if acc['id'] == message.text), None)
    if not selected:
        await message.answer("Неверный выбор счета!")
        return

    await message.answer(
        f"Баланс счета {selected['id']} ({selected['type']}): {selected['balance']}",
        reply_markup=main_keyboard
    )
    await state.clear()

async def run_cpp_command(args):
    try:
        proc = await asyncio.create_subprocess_exec(
            CPP_BINARY,
            *args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await proc.communicate()
        if proc.returncode != 0:
            return f"Ошибка: {stderr.decode().strip()}"
        return stdout.decode().strip()
    except Exception as e:
        logger.error(f"C++ error: {str(e)}")
        return "Произошла внутренняя ошибка"

def parse_accounts(output):
    accounts = []
    for line in output.split('\n'):
        if line.startswith("ACCOUNT|"):
            parts = line.split('|')
            accounts.append({
                'id': parts[1],
                'type': parts[2],
                'balance': parts[3]
            })
    return accounts

if __name__ == "__main__":
    if not os.path.exists(CPP_BINARY):
        raise FileNotFoundError(f"C++ binary not found at {CPP_BINARY}")
    asyncio.run(dp.start_polling(bot))
