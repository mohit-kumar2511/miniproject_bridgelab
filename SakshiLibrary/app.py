import os
from flask import Flask, render_template, request, redirect, url_for, flash, send_file, jsonify
from flask_login import LoginManager, login_user, login_required, logout_user, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from datetime import datetime, timedelta, date
from calendar import monthrange
from database import db, User, Student, Transaction, Expense, Settings, Locker
from xhtml2pdf import pisa 
import io

app = Flask(__name__)
app.config['SECRET_KEY'] = 'sakshi_library_secret_key_2025'
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///library.db'
app.config['UPLOAD_FOLDER'] = 'static/uploads/students'

db.init_app(app)
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# --- Helpers ---
def month_window(year, month):
    """Return first and last date for given month."""
    start = date(year, month, 1)
    end = date(year, month, monthrange(year, month)[1])
    return start, end

def student_flow(year, month):
    """Return monthly stats for new, renewals, churned, active_end, net_change."""
    start, end = month_window(year, month)

    new_students = Student.query.filter(
        Student.admission_date >= start,
        Student.admission_date <= end,
        Student.is_deleted == False
    ).count()

    renewals = Transaction.query.filter(
        Transaction.date >= start,
        Transaction.date <= end,
        Transaction.old_expiry < start
    ).count()

    active_end = Student.query.filter(
        Student.is_deleted == False,
        Student.expiry_date >= end
    ).count()

    # Students whose validity expired before this month and did not pay this month
    churned = Student.query.filter(
        Student.is_deleted == False,
        Student.expiry_date < start,
        ~Student.uid.in_(
            db.session.query(Transaction.student_uid).filter(
                Transaction.date >= start,
                Transaction.date <= end
            )
        )
    ).count()

    return {
        "month_label": start.strftime("%b %Y"),
        "new": new_students,
        "renewals": renewals,
        "active_end": active_end,
        "churned": churned,
        "net_change": new_students + renewals - churned
    }

def get_setting(key, default=None):
    with app.app_context():
        s = Settings.query.filter_by(key=key).first()
        return s.value if s else default

def set_setting(key, value):
    with app.app_context():
        s = Settings.query.filter_by(key=key).first()
        if not s:
            s = Settings(key=key)
            db.session.add(s)
        s.value = str(value)
        db.session.commit()

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

# --- Routes ---

@app.route('/')
def home():
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        user = User.query.filter_by(username=username).first()
        if user and check_password_hash(user.password, password):
            login_user(user)
            return redirect(url_for('dashboard'))
        flash('Invalid credentials', 'danger')
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
    today = date.today()
    students = Student.query.filter_by(is_deleted=False).all()
    due_count = 0
    almost_due = 0
    
    for s in students:
        if s.expiry_date:
            days_left = (s.expiry_date - today).days
            if days_left < 0:
                due_count += 1
            elif 0 <= days_left <= 5:
                almost_due += 1

    total_students = Student.query.filter_by(is_deleted=False).count()
    active_students = Student.query.filter_by(status='Active', is_deleted=False).count()
    demo_students_count = Student.query.filter_by(is_demo=True, is_deleted=False).count()
    lockers_used = Locker.query.filter_by(is_occupied=True).count()
    
    # Count boys and girls
    total_boys = Student.query.filter(
        db.or_(
            Student.gender == 'Male',
            Student.gender == 'Boy',
            Student.gender == 'M'
        ),
        Student.is_deleted == False
    ).count()
    
    total_girls = Student.query.filter(
        db.or_(
            Student.gender == 'Female',
            Student.gender == 'Girl',
            Student.gender == 'F'
        ),
        Student.is_deleted == False
    ).count()
    
    # Get total seats and lockers from settings
    total_seats = int(get_setting('total_seats', '50') or 50)
    total_lockers = int(get_setting('total_lockers', '30') or 30)
    
    # Booked seats = active students
    booked_seats = active_students
    
    first_day = today.replace(day=1)
    income = db.session.query(db.func.sum(Transaction.amount)).filter(Transaction.date >= first_day).scalar() or 0
    expenses = db.session.query(db.func.sum(Expense.amount)).filter(Expense.date >= first_day).scalar() or 0

    return render_template('dashboard.html', 
                           total=total_students, active=active_students, 
                           due=due_count, almost=almost_due,
                           lockers=lockers_used, income=income, expenses=expenses,
                           total_boys=total_boys, total_girls=total_girls,
                           total_seats=total_seats, booked_seats=booked_seats,
                           total_lockers=total_lockers, demo_students_count=demo_students_count)

@app.route('/students')
@login_required
def students_list():
    all_students = Student.query.filter_by(is_deleted=False).order_by(Student.id.desc()).all()
    today = date.today()
    return render_template('students.html', students=all_students, today=today, filter_title='All Students')

@app.route('/students/<filter_type>')
@login_required
def students_filtered(filter_type):
    today = date.today()
    query = Student.query.filter_by(is_deleted=False)
    
    if filter_type == 'boys':
        students = query.filter(
            db.or_(
                Student.gender == 'Male',
                Student.gender == 'Boy',
                Student.gender == 'M'
            )
        ).order_by(Student.id.desc()).all()
        filter_title = 'Boys Students'
    elif filter_type == 'girls':
        students = query.filter(
            db.or_(
                Student.gender == 'Female',
                Student.gender == 'Girl',
                Student.gender == 'F'
            )
        ).order_by(Student.id.desc()).all()
        filter_title = 'Girls Students'
    elif filter_type == 'overdue':
        students = []
        all_students = query.all()
        for s in all_students:
            if s.expiry_date and s.expiry_date < today:
                students.append(s)
        filter_title = 'Fees Overdue Students'
    elif filter_type == 'active':
        students = query.filter_by(status='Active').order_by(Student.id.desc()).all()
        filter_title = 'Active Students (Library Seats)'
    else:
        students = query.order_by(Student.id.desc()).all()
        filter_title = 'All Students'
    
    return render_template('students.html', students=students, today=today, filter_title=filter_title)

@app.route('/monthly_report')
@login_required
def monthly_report():
    """Monthly statistics report showing students, revenue, and expenses"""
    today = date.today()
    
    # Get last 12 months data
    months_data = []
    for i in range(12):
        # Calculate month start and end
        if today.month - i <= 0:
            month = 12 + (today.month - i)
            year = today.year - 1
        else:
            month = today.month - i
            year = today.year
        
        month_start = date(year, month, 1)
        if month == 12:
            month_end = date(year + 1, 1, 1) - timedelta(days=1)
        else:
            month_end = date(year, month + 1, 1) - timedelta(days=1)
        
        # Count active students at end of month (not deleted, not demo, expiry >= month_end)
        active_students = Student.query.filter(
            Student.is_deleted == False,
            Student.is_demo == False,
            Student.expiry_date >= month_end
        ).count()
        
        # Count total students (including demos) who were active during or at end of month
        # Students who were admitted before or during the month and not deleted
        total_students = Student.query.filter(
            Student.is_deleted == False,
            Student.admission_date <= month_end
        ).count()
        
        # Calculate income for the month
        month_income = db.session.query(db.func.sum(Transaction.amount)).filter(
            Transaction.date >= month_start,
            Transaction.date <= month_end
        ).scalar() or 0
        
        # Calculate expenses for the month
        month_expenses = db.session.query(db.func.sum(Expense.amount)).filter(
            Expense.date >= month_start,
            Expense.date <= month_end
        ).scalar() or 0
        
        # Net income
        net_income = month_income - month_expenses
        
        months_data.append({
            'month_label': month_start.strftime('%B %Y'),
            'month_start': month_start,
            'month_end': month_end,
            'active_students': active_students,
            'total_students': total_students,
            'income': month_income,
            'expenses': month_expenses,
            'net_income': net_income,
            'is_current': i == 0,
            'is_previous': i == 1
        })
    
    # Current month data
    current_month = months_data[0] if months_data else None
    previous_month = months_data[1] if len(months_data) > 1 else None
    
    return render_template('monthly_report.html',
                         current_month=current_month,
                         previous_month=previous_month,
                         months_data=reversed(months_data))  # Oldest to newest

@app.route('/income')
@login_required
def income_view():
    today = date.today()
    first_day = today.replace(day=1)
    
    # Get all transactions for current month
    transactions = Transaction.query.filter(Transaction.date >= first_day).order_by(Transaction.date.desc()).all()
    
    # Calculate totals
    total_income = db.session.query(db.func.sum(Transaction.amount)).filter(Transaction.date >= first_day).scalar() or 0
    total_expenses = db.session.query(db.func.sum(Expense.amount)).filter(Expense.date >= first_day).scalar() or 0
    net_income = total_income - total_expenses
    
    # Get expenses
    expenses = Expense.query.filter(Expense.date >= first_day).order_by(Expense.date.desc()).all()
    
    return render_template('income.html', 
                         transactions=transactions, 
                         expenses=expenses,
                         total_income=total_income,
                         total_expenses=total_expenses,
                         net_income=net_income,
                         month=today.strftime('%B %Y'))

@app.route('/student_stats')
@login_required
def student_stats():
    # Defaults: current month
    year = int(request.args.get('year', date.today().year))
    month = int(request.args.get('month', date.today().month))

    # Current month stats
    current_stats = student_flow(year, month)

    # Last 6 months including current (for quick trend)
    trend = []
    curr = date(year, month, 1)
    for _ in range(6):
        trend.append(student_flow(curr.year, curr.month))
        # move one month back
        if curr.month == 1:
            curr = date(curr.year - 1, 12, 1)
        else:
            curr = date(curr.year, curr.month - 1, 1)

    return render_template(
        'student_stats.html',
        stats=current_stats,
        trend=reversed(trend)  # oldest to newest for display
    )

@app.route('/lockers')
@login_required
def lockers_view():
    all_lockers = Locker.query.order_by(Locker.number).all()
    total_lockers = Locker.query.count()
    occupied_lockers = Locker.query.filter_by(is_occupied=True).count()
    available_lockers = total_lockers - occupied_lockers
    
    return render_template('lockers.html', 
                         lockers=all_lockers,
                         total=total_lockers,
                         occupied=occupied_lockers,
                         available=available_lockers)

@app.route('/check_demo_mobile')
@login_required
def check_demo_mobile():
    """AJAX endpoint to check if mobile exists in demo students"""
    mobile = request.args.get('mobile', '').strip().replace(' ', '').replace('-', '')
    if not mobile or len(mobile) < 10:
        return jsonify({'exists': False, 'demos': []})
    
    # Get all demo students and check mobile (normalize for comparison)
    all_demos = Student.query.filter_by(is_demo=True, is_deleted=False).all()
    existing_demos = []
    for demo in all_demos:
        demo_mobile = (demo.mobile or '').strip().replace(' ', '').replace('-', '')
        if demo_mobile == mobile:
            existing_demos.append(demo)
    
    existing_demos.sort(key=lambda x: x.admission_date or date.min, reverse=True)
    
    if existing_demos:
        demos_data = []
        for demo in existing_demos:
            demos_data.append({
                'uid': demo.uid,
                'name': demo.name,
                'admission_date': demo.admission_date.isoformat() if demo.admission_date else None,
                'expiry_date': demo.expiry_date.isoformat() if demo.expiry_date else None,
                'demo_days': demo.demo_days or 0,
                'address': demo.address or ''
            })
        return jsonify({'exists': True, 'demos': demos_data})
    
    return jsonify({'exists': False, 'demos': []})

@app.route('/add_student', methods=['GET', 'POST'])
@login_required
def add_student():
    if request.method == 'POST':
        is_demo = request.form.get('is_demo') == 'on'
        
        # Check if mobile exists in demo students
        mobile = request.form.get('mobile', '').strip()
        existing_demos = []
        if mobile:
            existing_demos = Student.query.filter_by(mobile=mobile, is_demo=True, is_deleted=False).order_by(Student.admission_date.desc()).all()
        
        last_id = get_setting('last_uid', '2025124')
        new_uid = str(int(last_id) + 1)
        
        photo = request.files.get('photo')
        filename = ''
        if photo and photo.filename:
            filename = secure_filename(f"{new_uid}_{photo.filename}")
            photo.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
        
        adm_date = datetime.strptime(request.form['admission_date'], '%Y-%m-%d').date()
        
        if is_demo:
            # Check if user confirmed to proceed with duplicate demo
            confirm_duplicate = request.form.get('confirm_duplicate_demo') == 'yes'
            
            # If existing demos found and not confirmed, redirect back with warning
            if existing_demos and not confirm_duplicate:
                flash('⚠️ यह mobile number पहले से demo entry में है! कृपया confirm करें कि आप फिर से demo देना चाहते हैं।', 'warning')
                return redirect(url_for('add_student', mobile=mobile))
            
            # Demo student - only basic info
            demo_days = int(request.form.get('demo_days', 7))
            notes_text = f"Demo student - {demo_days} days"
            if existing_demos:
                prev_demo_ids = ", ".join([d.uid for d in existing_demos])
                notes_text += f"; Previous demo entries: {prev_demo_ids} (Repeat demo)"
            
            new_student = Student(
                uid=new_uid,
                name=request.form['name'],
                mobile=request.form['mobile'],
                address=request.form.get('address', ''),
                admission_date=adm_date,
                expiry_date=adm_date + timedelta(days=demo_days),
                photo=filename,
                is_demo=True,
                status='Demo',
                demo_days=demo_days,
                notes=notes_text
            )
            db.session.add(new_student)
            set_setting('last_uid', new_uid)
            db.session.commit()
            flash(f'Demo Student Added! ID: {new_uid} ({demo_days} days)', 'success')
            return redirect(url_for('demo_students'))
        else:
            # Full admission
            pay_date_raw = request.form.get('payment_date')
            pay_date = datetime.strptime(pay_date_raw, '%Y-%m-%d').date() if pay_date_raw else date.today()

            library_fee = float(request.form.get('library_fee') or 0)
            discount = float(request.form.get('discount') or 0)
            amount_paid = float(request.form.get('amount_paid') or 0)
            due_amount = max(library_fee - discount - amount_paid, 0)

            locker_number = request.form.get('locker_number') or None
            seat_reserved = request.form.get('seat_reserved', 'no') == 'yes'
            payment_mode = request.form.get('payment_mode') or 'Cash'
            extra_notes = request.form.get('notes', '').strip()
            notes_text = f"Seat reserved: {'Yes' if seat_reserved else 'No'}; Payment mode: {payment_mode}; Locker: {locker_number or 'N/A'}; Discount: {discount}; Due: {due_amount}"
            if extra_notes:
                notes_text += f"; Notes: {extra_notes}"
            if existing_demos:
                demo_ids = ", ".join([d.uid for d in existing_demos])
                notes_text += f"; Previously demo student(s) (ID: {demo_ids})"
            
            new_student = Student(
                uid=new_uid,
                name=request.form['name'],
                father_name=request.form.get('father_name', ''),
                mobile=request.form['mobile'],
                gender=request.form.get('gender', ''),
                address=request.form.get('address', ''),
                admission_date=adm_date,
                expiry_date=adm_date + timedelta(days=30), 
                photo=filename,
                is_demo=False,
                locker_number=locker_number,
                notes=notes_text
            )
            
            db.session.add(new_student)
            
            # Initial admission transaction
            if amount_paid > 0:
                trans = Transaction(
                    student_uid=new_uid,
                    amount=amount_paid,
                    payment_type=f"Admission ({payment_mode})",
                    months_paid=1,
                    old_expiry=adm_date,
                    new_expiry=adm_date + timedelta(days=30),
                    date=datetime.combine(pay_date, datetime.min.time())
                )
                db.session.add(trans)

            set_setting('last_uid', new_uid)
            db.session.commit()
            flash(f'Student Added! ID: {new_uid}', 'success')
            return redirect(url_for('students_list'))
        
    # Check for existing demo by mobile
    mobile_search = request.args.get('mobile', '').strip()
    existing_demos = []
    if mobile_search:
        existing_demos = Student.query.filter_by(mobile=mobile_search, is_demo=True, is_deleted=False).order_by(Student.admission_date.desc()).all()
    
    return render_template('add_students.html', date=date, existing_demos=existing_demos, mobile_search=mobile_search)

@app.route('/update_student/<uid>', methods=['GET', 'POST'])
@login_required
def update_student(uid):
    student = Student.query.filter_by(uid=uid, is_deleted=False).first_or_404()
    
    if request.method == 'POST':
        student.name = request.form['name']
        student.father_name = request.form['father_name']
        student.mobile = request.form['mobile']
        student.gender = request.form.get('gender', '')
        student.address = request.form['address']
        student.admission_date = datetime.strptime(request.form['admission_date'], '%Y-%m-%d').date()
        student.is_demo = True if request.form.get('is_demo') else False
        
        # Handle photo update
        photo = request.files.get('photo')
        if photo and photo.filename != '':
            # Delete old photo if exists
            if student.photo:
                old_photo_path = os.path.join(app.config['UPLOAD_FOLDER'], student.photo)
                if os.path.exists(old_photo_path):
                    try:
                        os.remove(old_photo_path)
                    except:
                        pass
            filename = secure_filename(f"{uid}_{photo.filename}")
            photo.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
            student.photo = filename
        
        db.session.commit()
        flash(f'Student Updated Successfully!', 'success')
        return redirect(url_for('students_list'))
    
    return render_template('update_student.html', student=student)

@app.route('/delete_student/<uid>')
@login_required
def delete_student(uid):
    student = Student.query.filter_by(uid=uid, is_deleted=False).first_or_404()
    student.is_deleted = True
    student.deleted_at = datetime.utcnow()
    student.status = 'Inactive'
    db.session.commit()
    flash(f'Student moved to Recycle Bin!', 'warning')
    return redirect(url_for('students_list'))

@app.route('/demo_students')
@login_required
def demo_students():
    all_demos = Student.query.filter_by(is_demo=True, is_deleted=False).order_by(Student.admission_date.desc()).all()
    today = date.today()
    
    # Separate into active demos and expired demos
    active_demos = []
    expired_demos = []
    admitted_demos = []
    
    for demo in all_demos:
        if demo.expiry_date and demo.expiry_date < today:
            # Check if they took admission
            full_student = Student.query.filter_by(mobile=demo.mobile, is_demo=False, is_deleted=False).first()
            if full_student:
                admitted_demos.append(demo)
            else:
                expired_demos.append(demo)
        else:
            active_demos.append(demo)
    
    return render_template('demo_students.html', 
                         active_demos=active_demos,
                         expired_demos=expired_demos,
                         admitted_demos=admitted_demos,
                         today=today)

@app.route('/admit_demo_student/<uid>', methods=['GET', 'POST'])
@login_required
def admit_demo_student(uid):
    demo_student = Student.query.filter_by(uid=uid, is_demo=True, is_deleted=False).first_or_404()
    
    if request.method == 'POST':
        last_id = get_setting('last_uid', '2025124')
        new_uid = str(int(last_id) + 1)
        
        photo = request.files.get('photo')
        filename = demo_student.photo  # Keep old photo if exists
        if photo and photo.filename:
            filename = secure_filename(f"{new_uid}_{photo.filename}")
            photo.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
        
        adm_date = datetime.strptime(request.form['admission_date'], '%Y-%m-%d').date()
        pay_date_raw = request.form.get('payment_date')
        pay_date = datetime.strptime(pay_date_raw, '%Y-%m-%d').date() if pay_date_raw else date.today()

        library_fee = float(request.form.get('library_fee') or 0)
        discount = float(request.form.get('discount') or 0)
        amount_paid = float(request.form.get('amount_paid') or 0)
        due_amount = max(library_fee - discount - amount_paid, 0)

        locker_number = request.form.get('locker_number') or None
        seat_reserved = request.form.get('seat_reserved', 'no') == 'yes'
        payment_mode = request.form.get('payment_mode') or 'Cash'
        extra_notes = request.form.get('notes', '').strip()
        notes_text = f"Seat reserved: {'Yes' if seat_reserved else 'No'}; Payment mode: {payment_mode}; Locker: {locker_number or 'N/A'}; Discount: {discount}; Due: {due_amount}"
        if extra_notes:
            notes_text += f"; Notes: {extra_notes}"
        notes_text += f"; Previously demo student (ID: {demo_student.uid}, {demo_student.demo_days} days)"
        
        new_student = Student(
            uid=new_uid,
            name=request.form['name'],
            father_name=request.form.get('father_name', ''),
            mobile=request.form['mobile'],
            gender=request.form.get('gender', ''),
            address=request.form.get('address', ''),
            admission_date=adm_date,
            expiry_date=adm_date + timedelta(days=30), 
            photo=filename,
            is_demo=False,
            locker_number=locker_number,
            notes=notes_text
        )
        
        db.session.add(new_student)
        
        # Mark demo student as deleted
        demo_student.is_deleted = True
        demo_student.deleted_at = datetime.utcnow()
        
        # Initial admission transaction
        if amount_paid > 0:
            trans = Transaction(
                student_uid=new_uid,
                amount=amount_paid,
                payment_type=f"Admission ({payment_mode})",
                months_paid=1,
                old_expiry=adm_date,
                new_expiry=adm_date + timedelta(days=30),
                date=datetime.combine(pay_date, datetime.min.time())
            )
            db.session.add(trans)

        set_setting('last_uid', new_uid)
        db.session.commit()
        flash(f'Demo Student Converted to Full Admission! New ID: {new_uid}', 'success')
        return redirect(url_for('students_list'))
    
    return render_template('admit_demo_student.html', demo_student=demo_student, date=date)

@app.route('/recycle_bin')
@login_required
def recycle_bin():
    deleted_students = Student.query.filter_by(is_deleted=True).order_by(Student.deleted_at.desc()).all()
    return render_template('recycle_bin.html', students=deleted_students)

@app.route('/restore_student/<uid>')
@login_required
def restore_student(uid):
    student = Student.query.filter_by(uid=uid, is_deleted=True).first_or_404()
    student.is_deleted = False
    student.deleted_at = None
    db.session.commit()
    flash(f'Student Restored Successfully!', 'success')
    return redirect(url_for('recycle_bin'))

@app.route('/permanent_delete_student/<uid>')
@login_required
def permanent_delete_student(uid):
    student = Student.query.filter_by(uid=uid, is_deleted=True).first_or_404()
    
    # Delete photo if exists
    if student.photo:
        photo_path = os.path.join(app.config['UPLOAD_FOLDER'], student.photo)
        if os.path.exists(photo_path):
            os.remove(photo_path)
    
    # Delete related transactions
    Transaction.query.filter_by(student_uid=uid).delete()
    
    # Free locker if assigned
    if student.locker_number:
        locker = Locker.query.filter_by(number=student.locker_number).first()
        if locker:
            locker.is_occupied = False
            locker.student_uid = None
    
    db.session.delete(student)
    db.session.commit()
    flash(f'Student Permanently Deleted!', 'danger')
    return redirect(url_for('recycle_bin'))

@app.route('/fees/<uid>', methods=['GET', 'POST'])
@login_required
def fees(uid):
    student = Student.query.filter_by(uid=uid, is_deleted=False).first_or_404()
    if request.method == 'POST':
        months = int(request.form['months'])
        amount = float(request.form['amount'])
        
        old_expiry = student.expiry_date
        today = date.today()
        
        if old_expiry < today:
            new_expiry = today + timedelta(days=30 * months)
        else:
            new_expiry = old_expiry + timedelta(days=30 * months)
            
        student.expiry_date = new_expiry
        student.status = 'Active'
        
        trans = Transaction(
            student_uid=uid, amount=amount, payment_type='Monthly Fee',
            months_paid=months, old_expiry=old_expiry, new_expiry=new_expiry
        )
        
        db.session.add(trans)
        db.session.commit()
        
        return redirect(url_for('generate_slip', tid=trans.id))
        
    return render_template('fees.html', student=student)

@app.route('/slip/<tid>')
@login_required
def generate_slip(tid):
    try:
        trans = Transaction.query.get(tid)
        if not trans:
            flash('Transaction not found', 'danger')
            return redirect(url_for('dashboard'))
        
        student = Student.query.filter_by(uid=trans.student_uid, is_deleted=False).first_or_404()
        rendered = render_template('slip_template.html', t=trans, s=student, now=datetime.now())
        pdf_path = os.path.join('static/receipts', f"{trans.id}.pdf")
        
        # Ensure receipts directory exists
        os.makedirs('static/receipts', exist_ok=True)
        
        with open(pdf_path, "w+b") as result_file:
            pdf = pisa.CreatePDF(io.BytesIO(rendered.encode('utf-8')), dest=result_file)
            if pdf.err:
                flash('Error generating PDF', 'danger')
                return redirect(url_for('dashboard'))
        
        return send_file(pdf_path, as_attachment=True)
    except Exception as e:
        flash(f'Error generating receipt: {str(e)}', 'danger')
        return redirect(url_for('dashboard'))

@app.route('/settings', methods=['GET', 'POST'])
@login_required
def settings():
    if current_user.role != 'admin':
        flash('Access Denied', 'danger')
        return redirect(url_for('dashboard'))
        
    if request.method == 'POST':
        # Text Settings Save करें
        set_setting('library_name', request.form['library_name'])
        set_setting('address', request.form['address'])
        set_setting('email_1', request.form['email_1'])
        set_setting('email_2', request.form['email_2'])
        set_setting('phone_1', request.form['phone_1'])
        set_setting('phone_2', request.form['phone_2'])
        set_setting('total_seats', request.form['total_seats'])
        set_setting('total_lockers', request.form['total_lockers'])
        set_setting('start_date', request.form['start_date'])
        set_setting('setup_cost', request.form['setup_cost'])
        
        # Fees Settings
        set_setting('monthly_fee', request.form['monthly_fee'])
        set_setting('locker_fee', request.form['locker_fee'])
        set_setting('seat_fee', request.form['seat_fee'])

        # Photo Upload Logic
        if 'library_photo' in request.files:
            file = request.files['library_photo']
            if file.filename != '':
                filename = secure_filename('library_logo.png') # हम नाम फिक्स रखेंगे ताकि पुराना रिप्लेस हो जाए
                file.save(os.path.join('static/uploads/library', filename))
                set_setting('library_photo', filename)

        flash('Settings Updated Successfully!', 'success')
        
    return render_template('settings.html', 
                           lib_name=get_setting('library_name', 'Sakshi Library'),
                           address=get_setting('address', ''),
                           email_1=get_setting('email_1', 'sslibrary1197@gmail.com'),
                           email_2=get_setting('email_2', ''),
                           phone_1=get_setting('phone_1', '7078547721'),
                           phone_2=get_setting('phone_2', ''),
                           total_seats=get_setting('total_seats', '50'),
                           total_lockers=get_setting('total_lockers', '30'),
                           start_date=get_setting('start_date', ''),
                           setup_cost=get_setting('setup_cost', '0'),
                           monthly_fee=get_setting('monthly_fee', '500'),
                           locker_fee=get_setting('locker_fee', '50'),
                           seat_fee=get_setting('seat_fee', '100'),
                           photo=get_setting('library_photo', None))
# --- Migration Helper ---
def migrate_database():
    """Add missing columns to existing database"""
    try:
        import sqlite3
        db_uri = app.config['SQLALCHEMY_DATABASE_URI']
        # Handle both sqlite:///path and sqlite:////absolute/path
        if db_uri.startswith('sqlite:///'):
            db_path = db_uri.replace('sqlite:///', '')
            # Check if it's in instance folder
            if not os.path.exists(db_path):
                db_path = os.path.join('instance', 'library.db')
            
            if os.path.exists(db_path):
                conn = sqlite3.connect(db_path)
                cursor = conn.cursor()
                
                # Check existing columns
                cursor.execute("PRAGMA table_info(student)")
                columns = [row[1] for row in cursor.fetchall()]
                
                # Add is_deleted if missing
                if 'is_deleted' not in columns:
                    cursor.execute("ALTER TABLE student ADD COLUMN is_deleted BOOLEAN DEFAULT 0")
                    conn.commit()
                    print("✅ Added is_deleted column to student table")
                
                # Add deleted_at if missing
                if 'deleted_at' not in columns:
                    cursor.execute("ALTER TABLE student ADD COLUMN deleted_at DATETIME")
                    conn.commit()
                    print("✅ Added deleted_at column to student table")
                
                # Add demo_days if missing
                if 'demo_days' not in columns:
                    cursor.execute("ALTER TABLE student ADD COLUMN demo_days INTEGER")
                    conn.commit()
                    print("✅ Added demo_days column to student table")
                
                conn.close()
    except Exception as e:
        print(f"Migration note: {e}")

# --- Init DB ---
with app.app_context():
    db.create_all()
    migrate_database()  # Run migration to add new columns
    if not User.query.filter_by(username='admin').first():
        hashed = generate_password_hash('admin123', method='pbkdf2:sha256')
        admin = User(username='admin', password=hashed, role='admin')
        db.session.add(admin)
        db.session.commit()

if __name__ == '__main__':
    if not os.path.exists(app.config['UPLOAD_FOLDER']):
        os.makedirs(app.config['UPLOAD_FOLDER'])
    if not os.path.exists('static/receipts'):
        os.makedirs('static/receipts')
    if not os.path.exists('static/uploads/library'):
        os.makedirs('static/uploads/library')
    
    # Get local IP address for phone access
    try:
        import socket
        hostname = socket.gethostname()
        try:
            local_ip = socket.gethostbyname(hostname)
        except socket.gaierror:
            # Fallback if hostname resolution fails
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            try:
                s.connect(('8.8.8.8', 80))
                local_ip = s.getsockname()[0]
            except Exception:
                local_ip = '127.0.0.1'
            finally:
                s.close()
    except Exception as e:
        local_ip = '127.0.0.1'
        print(f"Warning: Could not determine local IP: {e}")
    
    print(f"\n{'='*50}")
    print(f"🌐 Server running on:")
    print(f"   Local:   http://127.0.0.1:5000")
    print(f"   Network: http://{local_ip}:5000")
    print(f"   📱 Phone: Open browser and go to http://{local_ip}:5000")
    print(f"{'='*50}\n")
    
    app.run(debug=True, host='0.0.0.0', port=5000)