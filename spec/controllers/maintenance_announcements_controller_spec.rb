require 'spec_helper'

RSpec.describe MaintenanceAnnouncementsController, type: :controller do
    before(:each) do
        # stub sending of tickets
        allow(TicketService).to receive(:send).and_return(true)
        
        @template = FactoryGirl.create(:maintenance_template)
        @current_user = FactoryGirl.create :user
        @owner0 = FactoryGirl.create(:owner, users: [@current_user])
        @owner1 = FactoryGirl.create(:owner, users: [@current_user])
        allow(User).to receive(:current).and_return(@current_user)
        controller.session[:user_id] = @current_user.id
    end

    describe "POST create, successful" do
        before(:each) do
            @t = Time.now
            @m0 = FactoryGirl.create(:machine, owner: @owner0)
            @m1 = FactoryGirl.create(:machine, owner: @owner0)
            @m2 = FactoryGirl.create(:machine, owner: @owner1)
            @m3 = FactoryGirl.create(:machine, owner: @owner1)
        end
    
        it "creates a new maintenance announcement affecting a single owner" do
            post :create, params: { date: "#{@t.year}-#{@t.month}-#{@t.day}", reason: "reason", impact: "impact", template_id: @template.id, machine_ids: [ @m0.id, @m1.id ] }
            expect(MaintenanceAnnouncement.last.date).to eq("#{@t.year}-#{@t.month}-#{@t.day}")
            expect(MaintenanceAnnouncement.last.reason).to eq("reason")
            expect(MaintenanceAnnouncement.last.impact).to eq("impact")
            expect(MaintenanceTicket.last.machines.size).to eq(2)
            expect(MaintenanceTicket.last.machines.first).to eq(@m0)
            expect(MaintenanceTicket.last.machines.second).to eq(@m1)
        end

        it "creates a new maintenance announcement affecting multiple owners" do
            post :create, params: {date: "#{@t.year}-#{@t.month}-#{@t.day}", reason: "reason", impact: "impact", template_id: @template.id, machine_ids: [ @m0.id, @m1.id, @m2.id, @m3.id ] }
            expect(MaintenanceAnnouncement.last.date).to eq("#{@t.year}-#{@t.month}-#{@t.day}")
            expect(MaintenanceAnnouncement.last.reason).to eq("reason")
            expect(MaintenanceAnnouncement.last.impact).to eq("impact")
            expect(MaintenanceTicket.first.machines.size).to eq(2)
            expect(MaintenanceTicket.first.machines.first).to eq(@m0)
            expect(MaintenanceTicket.first.machines.second).to eq(@m1)
            expect(MaintenanceTicket.second.machines.size).to eq(2)
            expect(MaintenanceTicket.second.machines.first).to eq(@m2)
            expect(MaintenanceTicket.second.machines.second).to eq(@m3)
        end
    end

    describe "POST create, unselected VMs and not ignoring" do
        before(:each) do
            @t = Time.now
            @m0 = FactoryGirl.create(:machine, owner: @owner0)
            @m1 = FactoryGirl.create(:virtual_machine, owner: @owner0, vmhost: @m0.fqdn)
        end
    
        it "renders new" do
            post :create, params: {date: "#{@t.year}-#{@t.month}-#{@t.day}", reason: "reason", impact: "impact", template_id: @template.id, machine_ids: [ @m0.id ] }
            expect(response).to render_template("maintenance_announcements/new")
        end
    end

    describe "POST create, unselected VMs and ignoring" do
        before(:each) do
            @t = Time.now
            @m0 = FactoryGirl.create(:machine, owner: @owner0)
            @vm0 = FactoryGirl.create(:virtual_machine, owner: @owner0, vmhost: @m0.fqdn)
            @vm1 = FactoryGirl.create(:virtual_machine, owner: @owner0, vmhost: @m0.fqdn)
        end
    
        it "creates a new maintenance announcement" do
            post :create, params: {date: "#{@t.year}-#{@t.month}-#{@t.day}", reason: "reason", impact: "impact", template_id: @template.id, machine_ids: [ @m0.id, @vm0.id ], ignore_vms: true }
            expect(MaintenanceAnnouncement.last.date).to eq("#{@t.year}-#{@t.month}-#{@t.day}")
            expect(MaintenanceAnnouncement.last.reason).to eq("reason")
            expect(MaintenanceAnnouncement.last.impact).to eq("impact")
            expect(MaintenanceTicket.last.machines.size).to eq(2)
            expect(MaintenanceTicket.last.machines.first).to eq(@m0)
        end
    end

    describe "POST create, deadline exceeded" do
        before(:each) do
            @t = (Time.now + 7.days).strftime("%Y-%m-%d")
            @m0 = FactoryGirl.create(:machine, owner: @owner0, announcement_deadline: 7)
        end
    
        it "renders new" do
            post :create, params: {date: @t, reason: "reason", impact: "impact", template_id: @template.id, machine_ids: [ @m0.id ] }
            expect(response).to render_template("maintenance_announcements/new")
        end
    end

    describe "POST create, deadline exceeded and ignoring" do
        before(:each) do
            @t = (Time.now + 7.days).strftime("%Y-%m-%d")
            @m0 = FactoryGirl.create(:machine, owner: @owner0, announcement_deadline: 7)
        end
    
        it "creates a new maintenance announcement" do
            post :create, params: {date: @t, reason: "reason", impact: "impact", template_id: @template.id, machine_ids: [ @m0.id ], ignore_deadlines: true }
            expect(MaintenanceAnnouncement.last.date).to eq(@t)
            expect(MaintenanceAnnouncement.last.reason).to eq("reason")
            expect(MaintenanceAnnouncement.last.impact).to eq("impact")
            expect(MaintenanceTicket.last.machines.size).to eq(1)
            expect(MaintenanceTicket.last.machines.first).to eq(@m0)
        end
    end

    describe "POST create, deadline not exceeded" do
        before(:each) do
            @t = (Time.now + 14.days).strftime("%Y-%m-%d")
            @m0 = FactoryGirl.create(:machine, owner: @owner0, announcement_deadline: 7)
        end
    
        it "creates a new maintenance announcement" do
            post :create, params: {date: @t, reason: "reason", impact: "impact", template_id: @template.id, machine_ids: [ @m0.id ], ignore_deadlines: true }
            expect(MaintenanceAnnouncement.last.date).to eq(@t)
            expect(MaintenanceAnnouncement.last.reason).to eq("reason")
            expect(MaintenanceAnnouncement.last.impact).to eq("impact")
            expect(MaintenanceTicket.last.machines.size).to eq(1)
            expect(MaintenanceTicket.last.machines.first).to eq(@m0)
        end
    end
end
