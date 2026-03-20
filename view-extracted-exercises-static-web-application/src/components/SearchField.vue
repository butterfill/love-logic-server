<script setup>
defineProps({
  modelValue: {
    type: String,
    required: true
  },
  label: {
    type: String,
    required: true
  },
  placeholder: {
    type: String,
    required: true
  }
});

defineEmits(["update:modelValue"]);
</script>

<template>
  <label class="block">
    <span class="mb-2 block text-xs font-medium uppercase tracking-[0.25em] text-stone-500">{{ label }}</span>
    <input
      :value="modelValue"
      :placeholder="placeholder"
      type="search"
      class="w-full rounded-2xl border border-stone-300 bg-stone-50 px-4 py-3 text-sm text-stone-900 outline-none transition focus:border-stone-500 focus:bg-white"
      @input="$emit('update:modelValue', $event.target.value)"
    />
  </label>
</template>
