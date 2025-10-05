# HOWTO: Obtain a MIDI Manufacturer (SysEx) ID

## Purpose
This short guide explains how a company can obtain an official **MIDI Manufacturer (System Exclusive) ID**. This ID uniquely identifies your products in SysEx and related manufacturer-specific messaging, and is required for commercial releases.

---

## What is a Manufacturer (SysEx) ID?
- In MIDI, manufacturer-specific messages (SysEx) begin with your **Manufacturer ID** so only your devices/software act on them. The ID can be **1 byte** or **3 bytes** (extended).
- For development/education only, `0x7D` is reserved; **do not ship** products using it.

---

## Who issues the ID?
- **The MIDI Association (TMA/MMA)** issues Manufacturer SysEx IDs for hardware/software makers worldwide (outside Japan).
- **AMEI** (Japan) issues IDs for Japanese manufacturers.

---

## The practical path (outside Japan)

1. **Create an Individual (free) MIDI Association account**  
   Individual membership is free and is the starting point for all developer/corporate options.

2. **Choose your membership route**  
   Two main routes to obtain a Manufacturer ID:  
   - **SysEx ID Only membership** — aimed at smaller developers/startups; currently around **$240**.  
   - **Corporate membership** — tiered annual dues by company size; includes SysEx ID assignment.

3. **Submit the application**  
   - Log in with your Individual account and complete the SysEx ID enrollment or Corporate Membership application.  
   - Provide legal entity info and contact details.

4. **Payment & confirmation**  
   - Pay the applicable membership fee.  
   - Upon approval, you’ll be assigned a **Manufacturer ID** and appear in the official registry.

5. **Use your ID correctly**  
   - Prefix your SysEx messages (and identity/property messages that require it) with your assigned ID.  
   - Keep your membership in good standing.

---

## The practical path (Japan)
If your company is a **Japanese manufacturer**, apply via **AMEI** for a System Exclusive ID; AMEI maintains the database and assigns one ID per manufacturer after application and fee.

---

## Checklist
- [ ] Create free Individual account at the MIDI Association  
- [ ] Pick **SysEx ID Only** or **Corporate membership**  
- [ ] Submit application + payment  
- [ ] Receive assigned **Manufacturer ID**; record it in engineering docs  
- [ ] Update products to use your ID in SysEx and documentation  
- [ ] Keep membership current (annual dues)

---

## Notes
- SysEx messages always start with Manufacturer ID, then device/product data.  
- `0x7D` is for non-commercial, educational use only.  
- Corporate membership dues include the SysEx ID fee.  
- Your official listing is maintained by the MIDI Association (outside Japan) or AMEI (Japan).
