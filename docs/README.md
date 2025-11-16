I used claude code web (2025-11-14) to make these docs.

## Prompt

> This is an old project which continues to work well but will need an overhaul because it currently relies on an old stack, creating security and maintenance concerns. I am not yet sure whether it should simply be migrated to the latest meteor (which would be a lot of work as we are many versions out) or whether a fresh start, enabling a new stack, would be better. You will be helping me to explore the second possibility. Your task is to produce a set of documents which specify the project in sufficient detail for another developer to recreate it from scratch. To be clear, the new developer should not need to read any of the actual code, only the documents that you write. We do not want to add or remove features at this stage.

## Claude says
All documentation is now in version control and ready for use:

### Primary Specifications (8 documents, ~400KB)

1. ✅ **MASTER\_SPECIFICATION.md** - Start here! Executive summary & roadmap
2. ✅ **MONGODB\_SCHEMA.md** - Database schemas (7 collections)
3. ✅ **API\_METHODS\_ROUTES.md** - API endpoints (33 methods, 80+ routes)
4. ✅ **AUTHENTICATION\_AUTHORIZATION.md** - Security model
5. ✅ **UI\_COMPONENTS\_FLOWS.md** - User interface & workflows
6. ✅ **EXERCISE\_GRADING\_LOGIC.md** - Core IP: Automated grading algorithms ⭐
7. ✅ **UTILITIES\_AND\_HELPERS.md** - Helper functions & libraries
8. ✅ **DEPLOYMENT\_CONFIGURATION.md** - DevOps & deployment guide

### Quick References (4 documents)

9. ✅ **SCHEMA\_QUICK\_REFERENCE.md**
10. ✅ **SCHEMA\_INDEX.md**
11. ✅ **DOCUMENTATION\_SUMMARY.txt**
12. ✅ **AUTHENTICATION\_AUTHORIZATION\_SUMMARY.txt**

---

## 🎯 What You Now Have

These specifications provide everything needed to:

1. **Understand the complete system** without reading any source code
2. **Make an informed decision** about migrating Meteor vs. rebuilding on a new stack
3. **Estimate the effort** required for either approach (16-week roadmap provided)
4. **Hand off to developers** who can recreate the system from scratch
5. **Compare modern alternatives** against the current feature set
6. **Preserve the core IP** - especially the automated grading algorithms

---

## 💡 Recommended Next Steps

1. **Review MASTER\_SPECIFICATION.md** to get the complete overview
2. **Evaluate migration options:**
	- Option A: Migrate to latest Meteor (2.x → 3.x)
	- Option B: Rebuild on modern stack (e.g., Next.js + tRPC + MongoDB)
	- Option C: Hybrid approach (keep some components, rebuild others)
3. **Share documentation** with stakeholders or potential developers
4. **Cost/benefit analysis** using the 6-phase roadmap as a baseline

Your project is now fully documented and ready for the next phase of planning!