from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from datetime import datetime

db = SQLAlchemy()

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)
    role = db.Column(db.String(50), default='helper') # 'admin' or 'helper'
    email = db.Column(db.String(150))

class Student(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    uid = db.Column(db.String(20), unique=True, nullable=False)
    name = db.Column(db.String(100), nullable=False)
    father_name = db.Column(db.String(100))
    gender = db.Column(db.String(10))
    address = db.Column(db.String(200))
    mobile = db.Column(db.String(15))
    admission_date = db.Column(db.Date)
    photo = db.Column(db.String(200)) # Path to file
    status = db.Column(db.String(20), default='Active') # Active, Inactive, Demo
    expiry_date = db.Column(db.Date)
    locker_number = db.Column(db.String(20))
    notes = db.Column(db.Text)
    is_demo = db.Column(db.Boolean, default=False)
    demo_days = db.Column(db.Integer, nullable=True)  # Number of demo days
    is_deleted = db.Column(db.Boolean, default=False)
    deleted_at = db.Column(db.DateTime, nullable=True)
    
class Transaction(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    student_uid = db.Column(db.String(20), db.ForeignKey('student.uid'))
    amount = db.Column(db.Float)
    payment_type = db.Column(db.String(50)) # Monthly, Locker, Reg
    months_paid = db.Column(db.Integer, default=1)
    date = db.Column(db.DateTime, default=datetime.utcnow)
    old_expiry = db.Column(db.Date)
    new_expiry = db.Column(db.Date)
    
class Expense(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100))
    amount = db.Column(db.Float)
    date = db.Column(db.Date, default=datetime.utcnow)
    category = db.Column(db.String(50))

class Settings(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    key = db.Column(db.String(50), unique=True)
    value = db.Column(db.Text)

class Locker(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    number = db.Column(db.String(10), unique=True)
    is_occupied = db.Column(db.Boolean, default=False)
    student_uid = db.Column(db.String(20), nullable=True)