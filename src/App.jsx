import React, { useState } from "react"
import StudentList from "./components/StudentList.jsx"
import StudentForm from "./components/StudentForm.jsx"
import StudentDetails from "./components/StudentDetails.jsx"
import { getAllKids, makeKid, changeKid, killKid } from "./services/studentService.js"

export default function App() {
  const [all, setAll] = useState([])
  const [mode, setMode] = useState("list")
  const [pick, setPick] = useState(null)
  const [loading, setLoading] = useState(false)
  const [viewTab, setViewTab] = useState("list")

  async function loadNow() {
    try {
      setLoading(true)
      const d = await getAllKids()
      setAll(d)
    } catch (e) {
      alert("cant load")
    } finally {
      setLoading(false)
    }
  }

  function openAdd() {
    setPick(null)
    setMode("form")
  }

  function openEdit(x) {
    setPick(x)
    setMode("form")
  }

  function openDetail(x) {
    setPick(x)
    setMode("details")
  }

  function goBackList() {
    setMode("list")
  }

  async function saveThing(body) {
    try {
      if (pick && pick.id) {
        await changeKid(pick.id, body)
        alert("edited, now click load students")
      } else {
        await makeKid(body)
        alert("added, now click load students")
      }
      setMode("list")
    } catch (e) {
      alert("cant save")
    }
  }

  async function removeOne(x) {
    const ok = window.confirm("delete this student?")
    if (!ok) return
    try {
      await killKid(x.id)
      alert("deleted, now click load students")
    } catch (e) {
      alert("cant delete")
    }
  }

  let mid
  if (mode === "form") {
    mid = <StudentForm one={pick} onSave={saveThing} onBack={goBackList} />
  } else if (mode === "details") {
    mid = <StudentDetails one={pick} onBack={goBackList} />
  } else {
    mid = (
      <StudentList
        data={all}
        onLoad={loadNow}
        onAdd={openAdd}
        onEdit={openEdit}
        onDelete={removeOne}
        onView={openDetail}
        loading={loading}
      />
    )
  }

  return (
    <div className="outerBox">
      <div className="tinyPage">
        <div className="topHead">
          <div>
            <h1>🎓 Student Management System</h1>
            <div className="tinyNote">✨ Manage student records with ease - Add, View, Edit & Delete</div>
          </div>
          <div className="badTabs">
            <button
              className={viewTab === "list" ? "onTab" : ""}
              onClick={() => {
                setViewTab("list")
                setMode("list")
              }}
            >
              📋 List
            </button>
            <button
              className={viewTab === "form" ? "onTab" : ""}
              onClick={() => {
                setViewTab("form")
                setMode("form")
              }}
            >
              ✏️ Form
            </button>
            <button
              className={viewTab === "details" ? "onTab" : ""}
              onClick={() => {
                setViewTab("details")
                setMode("details")
              }}
            >
              👁️ Details
            </button>
          </div>
        </div>
        <div className={mode === "list" ? "dataArea" : "dataSolo"}>
          {mid}
          {mode === "list" && (
            <div className="rightSide">
              <div className="boxy">
                <h3>ℹ️ Quick Guide</h3>
                <ul className="rightList">
                  <li className="rightItem">
                    <span>📥 How to Load</span>
                    <span>Click Load Students</span>
                  </li>
                  <li className="rightItem">
                    <span>💾 After Changes</span>
                    <span>Reload to see updates</span>
                  </li>
                  <li className="rightItem">
                    <span>💿 Data Storage</span>
                    <span>JSON Server (db.json)</span>
                  </li>
                </ul>
              </div>
              <div className="boxy">
                <h3>📊 Quick Stats</h3>
                <ul className="rightList">
                  <li className="rightItem">
                    <span>👥 Total Students</span>
                    <span style={{fontWeight: '700', color: '#667eea'}}>{all.length}</span>
                  </li>
                  <li className="rightItem">
                    <span>📈 Average Marks</span>
                    <span style={{fontWeight: '700', color: '#10b981'}}>
                      {all.length
                        ? Math.round(
                            all.reduce((a, b) => a + (Number(b.marks) || 0), 0) /
                              all.length
                          )
                        : "-"}
                    </span>
                  </li>
                </ul>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}



