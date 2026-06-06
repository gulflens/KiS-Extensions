import SwiftUI

struct ShortcutSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Overview
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("How it works", systemImage: "arrow.triangle.2.circlepath")
                                .font(.headline)
                            Text("An Apple Shortcut runs JavaScript on the crew portal page in Safari to extract trip and crew data. The data is copied to your clipboard, then the app opens and imports it automatically.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Step-by-step
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Setup Steps", systemImage: "list.number")
                                .font(.headline)

                            stepView(number: 1, title: "Allow JavaScript in Shortcuts",
                                     detail: "Go to Settings > Shortcuts > Advanced and enable \"Allow Running Scripts\"")

                            stepView(number: 2, title: "Create a new Shortcut",
                                     detail: "Open the Shortcuts app and tap \"+\" to create a new shortcut. Name it \"KiS Extensions\"")

                            stepView(number: 3, title: "Add: Run JavaScript on Web Page",
                                     detail: "Search for \"Run JavaScript on Web Page\" action. Paste the script below into it.")

                            stepView(number: 4, title: "Add: Copy to Clipboard",
                                     detail: "Add \"Copy to Clipboard\" action. Set its input to \"Shortcut Result\" from the previous step.")

                            stepView(number: 5, title: "Add: Open URLs",
                                     detail: "Add \"Open URLs\" action. Type: kisextensions://import")

                            stepView(number: 6, title: "Enable in Share Sheet",
                                     detail: "Tap the shortcut settings (i) and enable \"Show in Share Sheet\"")

                            stepView(number: 7, title: "Use it!",
                                     detail: "On the crew portal in Safari, tap Share > KiS Extensions. The app will open with your trips loaded.")
                        }
                    }

                    // Script
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("JavaScript for Step 3", systemImage: "doc.text")
                                    .font(.headline)
                                Spacer()
                                Button {
                                    copyScript()
                                } label: {
                                    Label(copied ? "Copied!" : "Copy Script", systemImage: copied ? "checkmark" : "doc.on.clipboard")
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }

                            Text(shortcutScript)
                                .font(.system(size: 10, design: .monospaced))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .frame(maxHeight: 200)
                        }
                    }

                    // URL Scheme info
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("URL Scheme", systemImage: "link")
                                .font(.headline)
                            Text("The app responds to:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text("kisextensions://import")
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(6)
                                Spacer()
                            }

                            Text("When opened via this URL, the app reads JSON from the clipboard and imports it automatically.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Shortcut Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func stepView(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func copyScript() {
        UIPasteboard.general.string = shortcutScript
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }

    private var shortcutScript: String {
        """
        function safeParse(str){try{return JSON.parse(str)}catch(e){return null}}
        function transformFormat(str){let f=str.split("_")[1];let t=str.split("_")[2].split("-",3);t[1]=(parseInt(t[1])+1).toString();t[2]=(parseInt(t[2])+2000).toString();t.forEach((n,i)=>t[i]=n.padStart(2,"0"));return f+"_"+t.join("/")}
        function convertDate(s){let[d,m,y]=s.split(" ",1)[0].split("/");return[parseInt(m),d,y].join("/")+" "+s.split(" ")[1]}
        let u=localStorage.getItem("CurrentStaffNo"),c=Object.keys(localStorage).filter(k=>k.startsWith("Crew_")&&!k.endsWith("TimeOut")),r=Object.keys(localStorage).filter(k=>k.startsWith("Roster_"+u)&&!k.endsWith("TimeOut")&&!k.endsWith("Destination")),f=Object.keys(localStorage).filter(m=>m.startsWith("Position_")&&!m.endsWith("TimeOut")),d={},ro=[];
        r.forEach(i=>{let v=safeParse(localStorage.getItem(i));if(v)ro.push(v)});
        ro.forEach(i=>i.StaffRosters[0].RosterData.CrewRosterResonse.Trips.Trp.forEach(s=>d[s.TripNo+"_"+s.StartDate.split(" ",1)]={}));
        c.forEach(i=>{let v=safeParse(localStorage.getItem(i));if(v){let k=transformFormat(i);if(d[k])d[k].crewData=v}});
        f.forEach(i=>{let v=safeParse(localStorage.getItem(i));if(v){let k=i.split(" ",1)[0].split("_").slice(-2).join("_");if(d[k])d[k].flightData=v}});
        ro.forEach(i=>i.StaffRosters[0].RosterData.CrewRosterResonse.Trips.Trp.forEach(s=>{let k=s.TripNo+"_"+s.StartDate.split(" ",1)[0];if(!d[k])d[k]={};d[k].shortInfo={};d[k].shortInfo.sectors=s.Dty.length;d[k].shortInfo.flightNumber=s.Dty[0].Flt[0].FltNo;d[k].shortInfo.flightDate=new Date(convertDate(s.Dty[0].Flt[0].DepDate)).toISOString();let l=["DXB"],la=[],du=[],sp=[];s.Dty.forEach(dt=>{sp.push(dt.Flt.length);dt.Flt.forEach(fl=>{if(fl.ArrStn!=="DXB"){l.push(fl.ArrStn);la.push(fl.LayOverTime)}du.push(fl.Duration)})});d[k].shortInfo.flightLegs=l;d[k].shortInfo.layovers=la;d[k].shortInfo.durations=du;d[k].shortInfo.sectorsPerDuty=sp;d[k].shortInfo.staff=u}));
        d=Object.entries(d).sort(([,a],[,b])=>new Date(a.shortInfo.flightDate)-new Date(b.shortInfo.flightDate)).reduce((r,[k,v])=>({...r,[k]:v}),{});
        completion(JSON.stringify(d));
        """
    }
}
