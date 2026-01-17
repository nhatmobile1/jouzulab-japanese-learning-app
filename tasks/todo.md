# UI Redesign: Phase 2 - Navigation & Browse Restructure

## Overview
Refine the JouzuLab iOS app based on user feedback and Bunpro design inspiration.

## Changes Requested

### 1. Tab Order Update
**New order:** Home → Study → Shadow → Browse → Settings

### 2. Browse View Restructure
**Current:** Flat list with scenario pills at top
**New:**
- JLPT level tabs at top (N5, N4, N3, N2, N1)
- Toggle between Vocab/Phrase/Sentence
- Scenario cards in main area (grid layout)
- Clicking scenario → shows filtered entry list

### 3. Bottom Tab Bar Style
**Current:** Floating pill/card style
**New:** Full-width bottom bar like Bunpro (dark background, fills safe area)

## Task Checklist

### Tab Navigation Updates
- [ ] Reorder tabs: Home, Study, Shadow, Browse, Settings
- [ ] Update tab bar to full-width style (not floating)
- [ ] Match Bunpro dark tab bar aesthetic

### Browse View Redesign
- [ ] Add JLPT level tab bar at top (N5, N4, N3, N2, N1)
- [ ] Add entry type toggle (Vocab/Phrase/Sentence)
- [ ] Create scenario card grid layout
- [ ] Scenario cards show icon, name, count
- [ ] Clicking scenario navigates to filtered list
- [ ] Remove "All" option - users must select JLPT + scenario

### Design Reference (Bunpro)
- Dark header/tab bar (#3D4447 or similar)
- Clean white/cream content cards
- Red/coral accent color for selected states
- Full-width bottom navigation
- Less rounded cards (8pt instead of 16pt)

## Files to Modify
- `ContentView.swift` - Tab order and tab bar style
- `BrowseView.swift` - Complete redesign with JLPT tabs + scenario grid
- `Theme.swift` - Add tab bar colors

## Waiting for Approval
Ready to implement these changes?
