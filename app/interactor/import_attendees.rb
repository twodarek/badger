class ImportAttendees
  include Interactor

  def call
    if context.file
      context.failed_imports = []
      context.attendees = import(context.file)
    else
      context.fail!(message: "Unable to import attendees")
    end
  end

  private

  def import(file)
    require "csv"

    CSV.foreach(file.path, headers: true) do |row|
      attendee = Attendee.find_or_create_by(email: row['Email_Address'], event_id: context.event_id)

      attendee.update_attributes(
        first_name: row['first_Name'],
        last_name: row['last_Name'],
        company: row['Company']
      )

      case row['RegTypeDescription']
      when /Sponsor/, /Sponsor Guest/
        attendee.update_attribute(:role, Role.find_by(name: "Sponsor"))
      when /SoftwareGR Board Member/, /GLSEC/
        attendee.update_attribute(:role, Role.find_by(name: "Organizer"))
      when /Guest/
        attendee.update_attribute(:role, Role.find_by(name: "Speaker"))
      when /Volunteer/
        attendee.update_attribute(:role, Role.find_by(name: "Volunteer"))
      else
        attendee.update_attribute(:role, Role.find_by(name: "Attendee"))
      end
    end
  end
end